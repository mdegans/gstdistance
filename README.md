# gstdistance
GStreamer social distancing plugin

This is a WIP plugin written in Vala.

While gst-cuda-filter is written in cpp and provides some elements, the plan is for this project to contain various reusable Gst.Bins for social distancing.

Why Vala? Because it's easier to deal with GObject and GStreamer in Vala. The boilerplate is handled for you and updated and the vala compiler is updated.

The only disadvantage is a lack of access to some useful GStreamer macros (and some of GstCheck, and GstHarness), which is why the elements themselves are written in c++. Standard GLib testing libraries will be used for integration testing.

Expect the repo to be updated over the summer along with the rest of the social distaicing work in progress.
