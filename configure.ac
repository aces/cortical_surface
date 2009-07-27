dnl Process this file with autoconf to produce a configure script.

AC_INIT([cortical_surface],[1.2.0],[Dave McDonald])
AC_CONFIG_SRCDIR([src/deform_surface.c])

AM_INIT_AUTOMAKE

AM_CONFIG_HEADER([config.h])

smr_WITH_BUILD_PATH

AC_PROG_INSTALL
AC_PROG_MAKE_SET
AC_PROG_CC

# Check for required C libraries
mni_REQUIRE_BICPL

# check for perl
AC_PATH_PROGS(PERL, [perl] )

AC_CONFIG_FILES([Makefile src/Makefile scripts/Makefile models/Makefile])
AC_OUTPUT(epm-header
scripts/cortical_surface
scripts/msd_masks
)

