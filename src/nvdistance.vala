/* nvdistance.vala
 *
 * Copyright 2020 Michael de Gans <47511965+mdegans@users.noreply.github.com>
 *
 * 66E67F6ADF56899B2AA37EF8BF1F2B9DFBB1D82E66BD48C05D8A73074A7D2B75
 * EB8AA44E3ACF111885E4F84D27DC01BB3BD8B322A9E8D7287AD20A6F6CD5CB1F
 *
 * This file is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

namespace Gst.Distance {

public class NvDistanceBin: Gst.Bin {
	public const uint DEFAULT_HEIGHT = 1280;
	public const uint DEFAULT_WIDTH = 720;
	public const uint DEFAULT_INTERVAL = 1;
	public const string DEFAULT_TRACKER_LIB = "libnvds_mot_iou.so";

	/**
	 * DeepStream nvsteammux element to mux multiple video streams into batches
	 * and attach metadata.
	 */
	protected dynamic Gst.Element muxer;
	/**
	 * DeepStream nvinfer primary inference element to perform detectons on batches.
	 */
	protected dynamic Gst.Element pie;
	/**
	 * DeepStream nvtracker element to track objects across batches.
	 */
	protected dynamic Gst.Element tracker;
	/**
	 * DeepStream nvtiler element to tile objects.
	 */
	protected dynamic Gst.Element tiler;
	/**
	 * DeepsStream nvvideoconvert element to convert video for the osd.
	 */
	protected Gst.Element osd_conv;
	/**
	 * DeepStream nvosd element to draw on the image.
	 */
	protected Gst.Element osd;

	protected uint _class_id;
	/**
	* The class id of a person.
	*/
	public uint class_id {
		get {
			return this._class_id;
		}
		set {
			this._class_id = value;
			// TODO(mdegans): check pie in NULL or READY before setting
			this.pie.infer_on_class_ids = value.to_string();
		}
	}

	/**
	 * Tells the video stream muxer if sources are live (eg. rtsp).
	 */
	public bool live_source {
		get {
			return this.muxer.live_source;
		}
		set {
			this.muxer.live_source = value;
		}
	}

	protected uint _max_num_sources;
	/**
	 * The maximum number of sources.
	 * 
	 * This configures:
	 * * muxer resolution
	 * * tiler resolution
	 * * tiler rows and columns
	 * * muxer batch size
	 * * pie batch size
	 */
	public uint max_num_sources {
		get {
			return this._max_num_sources;
		}
		set {
			this._max_num_sources = value;
			this.muxer.batch_size = value;
			this.pie.batch_size = value;
			// reconfigure resolution
			this.tiler.rows = this.rows_and_colunns;
			this.tiler.columns = this.rows_and_colunns;
			this.width = this.width;
			this.height = this.height;
		}
	}

	/**
	 * Get the number of connected sources (from the muxer.numsinkpads).
	 */
	protected int num_connected_sources {
		get {
			lock (this.muxer) {
				return this.muxer.numsinkpads;
			}
		}
	}

	/**
	 * Number of rows and columns the tiler is using.
	 * 
	 * This is calculated from @max_num_sources
	 */
	public uint rows_and_colunns {
		get {
			return calc_rows_and_columns(this.max_num_sources);
		}
	}

	/**
	 * Output height.
	 */
	public uint height {
		get {
			return this.tiler.height;
		}
		set {
			this.tiler.height = value;
			this.muxer.height = value / this.rows_and_colunns;
		}
	}

	/**
	 * Output width.
	 */
	public uint width {
		get {
			return this.tiler.width;
		}
		set {
			this.tiler.width = value;
			this.muxer.width = value / this.rows_and_colunns;
		}
	}

	/**
	 * Maintain apsect ratio when scaling.
	 */
	public bool maintain_aspect_ratio {
		get {
			return this.muxer.enable_padding;
		}
		set {
			this.muxer.enable_padding = value;
		}
	}

	/**
	 * Primary inference engine (nvinfer) config filename.
	 */
	public string pie_config_file {
		get {
			return this.pie.config_file_path;
		}
		set {
			this.pie.config_file_path = value;
		}
	}

	/**
	 * Tracker (nvtracker) config filename.
	 */
	public string tracker_config_file {
		get {
			return this.tracker.ll_config_file;
		}
		set {
			this.tracker._ll_config_file = value;
		}
	}

	/**
	 * id of the buffer probe callback.
	 */
	protected ulong? _buffer_probe_id = null;

	protected string _latest_record;
	/**
	 * The latest record as a protbuf string.
	 */
	public string latest_record {
		get {
			// FIXME(mdegans): this might need a lock
			return this._latest_record;
		}
	}

	/**
	 * Construct a DeepStream distancing {@link Gst.Bin}.
	 *
	 * @param name an optional name for this bin.
	 */
	public NvDistanceBin(string? name) {
		if (name != null) {
			this.name = name;
		}

		// create all elements (could check here, but the linking will fail if any failed to
		// be created, and it'll be logged in any case).
		this.muxer = Gst.ElementFactory.make("nvstreammuxer", "muxer");
		this.pie = Gst.ElementFactory.make("nvinfer", "pie");
		this.tracker = Gst.ElementFactory.make("nvtracker", "tracker");
		this.tiler = Gst.ElementFactory.make("nvtiler", "tiler");
		this.osd_conv = Gst.ElementFactory.make("nvvideoconvert", "osd_conv");
		this.osd = Gst.ElementFactory.make("nvosd", "osd");

		// set some default props
		this.maintain_aspect_ratio = true;
		this.height = DEFAULT_HEIGHT;
		this.width = DEFAULT_WIDTH;
		this.pie.interval = DEFAULT_INTERVAL;  // only do inference on every other frame
		// TODO(mdegans): set pie config file and paths
		this.tracker.ll_lib_file = DEFAULT_TRACKER_LIB;  // the iou tracker is good enough
		// TODO(mdegans): add tracker config file
		this.tracker.enable_batch_process = true;

		// add all elements to bin (could do this one by one and check, but the errors are logged anyway)
		// set GST_DEBUG environment variable to an integer (eg. 4) to view details.
		this.add_many(this.muxer, this.pie, this.tracker, this.tiler, this.osd_conv, this.osd);

		// link all elements (if this fails, something probably went wrong above)
		if (!this.muxer.link_many(this.pie, this.tracker, this.tiler, this.osd_conv, this.osd)) {
			critical("could not link nvinfer ! nvtracker ! nvtiler ! nvvideoconvert ! nvosd ! ");
		}

		// ghost the source pad of the osd to the outside
		var osd_src = this.osd.get_static_pad("src");
		var outer_src = new GhostPad.from_template("src", osd_src, osd_src.padtemplate);
		this.add_pad(outer_src);

		// connect the pad probe callback
		var osd_pad = this.osd.get_static_pad("sink");
		this._buffer_probe_id = osd_pad.add_probe(Gst.PadProbeType.BUFFER, on_buffer);
	}

	/**
	 * osd pad buffer probe callback.
	 */
	public virtual Gst.PadProbeReturn on_buffer(Gst.Pad pad, Gst.PadProbeInfo info) {
		// do our detection stuff, get the metadata back, and stick it on a property.
		string record = "";
		this._latest_record = record;
		return Gst.PadProbeReturn.OK;
	}

	/**
	 * Returns a sink from the stream muxer.
	 * 
	 * {@inheritDoc}
	 */
	public virtual new Gst.Pad? get_request_pad(string name) {
		// check if somebody (like me) requested the wrong pad type
		// because really, "src" and "sink" can be confusing terms.
		if (name.contains("src")) {
			warning(@"src pad requested but only sink pads available for request from $(this.get_class().get_name())");
			return null;
		}
		// lock the stream muxer so we don't request multiple identical pads
		lock (this.muxer) {  // this syntax is cool. cleaner than c++
			string sink_name = @"sink_$(this.muxer.numsinkpads)";
			var inner = this.muxer.get_request_pad(sink_name);
			if (inner == null) {
				warning(@"failed to request pad $(sink_name) from $(this.muxer.name)");
				return null;
			}
			var outer = new Gst.GhostPad.from_template(sink_name, inner, inner.padtemplate);
			if (outer == null) {
				warning(@"failed to ghost $(inner.name) onto $(this.name)");
				this.muxer.release_request_pad(inner);
				return null;
			}
			if (!this.add_pad(outer)) {
				warning(@"unable to add $(outer.name):$(inner.name)");
				this.muxer.release_request_pad(inner);
				return null;
			}
			return outer; // return the outer ghosted pad
		}
	}

	/**
	 * {@inheritDoc}
	 */
	public virtual new void release_request_pad(Gst.Pad pad) {
		lock (this.muxer) {
			var outer = (Gst.GhostPad) pad;
			var inner = outer.get_target();
	
			if (!this.remove_pad(outer)) {
				warning(@"could not release $(outer.name)");
				return;
			}
			this.muxer.release_request_pad(inner);
		}
	}
}


} // namespace Gst.Distance
