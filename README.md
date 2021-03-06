easy_efl.sh
-----------

This is a script to compile and install the Enlightenment Foundation
Libraries and Enlightenment-DR19. The script is originally written by
[morlenxus](http://omicron.homeip.net).

This version is the patched version of the script.
Patched by P. Purkayastha (ppurka @ #e). Licensing terms are same as
original script (BSD License).

The patched version of the script has several modifications:

1. The build system has been changed. The script now compiles files in
   a temporary directory instead of the source files directory. The
   rationale for doing so is to make sure that the build directory is
   always clean.

2. The script keeps track of all the installed files by writing log files
   in `$HOME/.config/easy_efl`. The next time a package is updated, the
   script will remove the already installed files and then install the new
   files. This ensures that stale files do not remain installed.
   The unpatched version of the script can do this if you pass `--clean
   --clean --clean` (yes, three times) to it. The problem here is that it
   has to uninstall _before_ the compilation of the updated version. So,
   if the compilation fails, then you are left with no installed package.

3. (TODO:) You can provide user patches to the packages by making sure that the
   patches work with level `-p1`. For instance if you want to patch efl then
   the following should work:

    ```sh
    $ cd efl
    $ patch -p1 -i efl.patch
    ```

   This file efl.patch should be present in `$HOME/.config/easy_efl`
   directory. The patch should be always named as `<package_name>.patch`.
   The package_name is the same name as the svn directory name (efl.patch
   for efl, enlightenment.patch for enlightenment, etc).

4. The script can backup your current installation if you provide the `-b`
   or `--backup` option.

