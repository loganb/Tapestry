Tapestry
============

Tapestry is a blocking to non-blocking adapter library that uses Fibers to make hide the complexity of actually writing non-blocking IO. A standard Cool.io event loop runs on one Fiber, while the user's code runs on one or more additional Fibers. Control is transfer to and from the user Fibers and the event loop Fiber to emulate blocking I/O. This allows modules to simultaneously (and mostly transparently) use blocking and evented coding styles within the same process. 

Contributing to Tapestry
------------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
--------

Copyright (c) 2012 Logan Bowers. See LICENSE.txt for
further details.

