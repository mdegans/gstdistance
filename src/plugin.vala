/* plugin.vala
 *
 * Copyright 2020 Michael de Gans <47511965+mdegans@users.noreply.github.com>
 * based off Vala boilerplate by Fabian Deutsch
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

const Gst.PluginDesc gst_plugin_desc = {
	1, 14, 
	"distance", 
	"Social Distancing plugin",
	plugin_init,
	"0.1",
	"LGPL",
	"https://github.com/mdegans/libgstdistance",
	"Package?",
	"Origin?"
};

public static bool plugin_init(Gst.Plugin p) {
#if DEEPSTREAM
	Gst.Element.register(
		p,
		"nvdistancebin",
		Gst.Rank.NONE,
		typeof(Gst.Distance.NvDistanceBin)
	);
#endif
#if CORAL
	// register coraldistancebin
#endif
	return true;
}

namespace Gst.Distance {
	//foo
}