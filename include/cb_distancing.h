#ifndef CB_DISTANCING_H__
#define CB_DISTANCING_H__

#include <gst/gst.h>
#include <glib.h>

G_BEGIN_DECLS  // extern "C" {

/**
 * nvosd_distance:
 * @info: (type GstPadProbeInfo*): #GstPadProbeInfo from a pad probe callback
 * of type buffer.
 *
 * Intended to be used with a social distancing pipeline.
 * 
 * makes boxes red for PERSON_CLASS_ID when they are
 * closer than the bbox height.
 *
 * Returns: true on succeess, false on failure
 *
 * Since: 0.1.0
 */
gboolean
on_buffer_osd_distance(GstPadProbeInfo * info);

G_END_DECLS // }

#endif // CB_DISTANCING_H__
