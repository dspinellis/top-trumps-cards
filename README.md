This project creates [Top Trumps](http://en.wikipedia.org/wiki/Top_trumps) cards for chemical elements.

* You can find the cards ready for printing through [this page](http://www.spinellis.gr/sw/top-trumps-cards/).
* You can read more about the project in [this blog entry](http://www.spinellis.gr/blog/20121021).

To create the HTML files you will need a Unix-compatible
shell command prompt (e.g. Linux, Mac OS X, FreeBSD, Solaris,
or Windows with Cygwin) with Perl, make, sed, and Netpbm installed.
At the prompt simply type ```make``` to create the HTML files.

Sadly, controlling for the page size is difficult with the current CSS
capabilities.
If your images don't line up on a grid, adjust the #element.height
property in the ```style.css``` file.
