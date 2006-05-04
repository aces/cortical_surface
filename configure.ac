dnl Process this file with autoconf to produce a configure script.

AC_INIT
AC_CONFIG_SRCDIR([src/deform_surface.c])
dnl AC_CONFIG_AUX_DIR(ac_config_aux)
AM_INIT_AUTOMAKE(cortical_surface, 1.1.1)
AM_CONFIG_HEADER([config.h])

AC_REVISION($Revision$)

AC_PROG_INSTALL
AC_PROG_MAKE_SET
AC_PROG_CC

smr_WITH_BUILD_PATH

# Check for required C libraries
mni_REQUIRE_BICPL

# check for perl
AC_PATH_PROGS(PERL, [perl] )

AC_CONFIG_FILES([Makefile src/Makefile scripts/Makefile models/Makefile])
AC_OUTPUT(epm-header
scripts/cortical_surface
scripts/msd_masks
)

