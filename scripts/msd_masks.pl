#!xPERLx -w
#---------------------------------------------------------------------------
#@COPYRIGHT :
#             Copyright 1998, Alex P. Zijdenbos
#             McConnell Brain Imaging Centre,
#             Montreal Neurological Institute, McGill University.
#             Permission to use, copy, modify, and distribute this
#             software and its documentation for any purpose and without
#             fee is hereby granted, provided that the above copyright
#             notice appear in all copies.  The author and McGill University
#             make no representations about the suitability of this
#             software for any purpose.  It is provided "as is" without
#             express or implied warranty.
#---------------------------------------------------------------------------- 
#$RCSfile$
#$Revision$
#$Author$
#$Date$
#$State$
#---------------------------------------------------------------------------

require 5.001;

use MNI::Startup;
use Getopt::Tabular;
use MNI::Spawn;
use MNI::FileUtilities qw(test_file check_output_dirs);
#use JobControl qw(AddProgramOptions Spawn);

#require "file_utilities.pl";
#require "path_utilities.pl";
#require "numeric_utilities.pl";
#require "minc_utilities.pl";
#require "volume_heuristics.pl";

#&Startup;	
&Initialize;	

# Created initial mask(ed volume)
$InitialMask = "${TmpDir}/initial_mask.mnc";
&Spawn("surface_mask2 $InputVolume $SurfaceObject $InitialMask");

# Resample to fix David's fixed x-y-z output dimension order
# (OK, OK, this is a bit of a brute force approach, but guaranteed to work)
$MaskedInput = "${TmpDir}/masked_input.mnc" if (!defined($MaskedInput));
&Spawn("mincresample -like $InputVolume $InitialMask $MaskedInput");

# Create binary mask (hoping that the source volume has no very small values)
$T = 0.01;
&Spawn("mincmath -byte -const2 -$T $T -nsegment $MaskedInput $Mask");

if (defined($DilatedMask)) {
    &Spawn(['dilate_volume', $Mask, $DilatedMask, 1, @Dilation]);
}

#&Cleanup (1);

# ------------------------------ MNI Header ----------------------------------
#@NAME       : &CreateInfoText
#@INPUT      : none
#@OUTPUT     : none
#@RETURNS    : nothing
#@DESCRIPTION: Sets the $Help, $Usage, $Version, and $LongVersion globals,
#              and registers the first two with ParseArgs so that user gets
#              useful error and help messages.
#@METHOD     : 
#@GLOBALS    : $Help, $Usage, $Version, $LongVersion
#@CALLS      : 
#@CREATED    : 95/08/25, Greg Ward (from code formerly in &ParseArgs)
#@MODIFIED   : 
#-----------------------------------------------------------------------------
sub CreateInfoText
{
   $Usage = <<USAGE;
Usage: $ProgramName [options] <in.mnc> <surface.obj> <mask.mnc>
       $ProgramName -help

USAGE

   $Help = <<HELP;
$ProgramName is a wrapper around surface_mask2, provinding some extra
functionality.
HELP

   &Getopt::Tabular::SetHelp ($Help, $Usage);
}

# ------------------------------ MNI Header ----------------------------------
#@NAME       : &SetupArgTables
#@INPUT      : none
#@OUTPUT     : none
#@RETURNS    : References to the four option tables:
#                @site_args
#                @pref_args
#                @protocol_args
#                @other_args
#@DESCRIPTION: Defines the tables of command line (and config file) 
#              options that we pass to ParseArgs.  There are four
#              separate groups of options, because not all of them
#              are valid in all places.  See comments in the routine
#              for details.
#@METHOD     : 
#@GLOBALS    : makes references to many globals (almost all of 'em in fact)
#              even though most of them won't have been defined when
#              this is called
#@CALLS      : 
#@CREATED    : 95/08/23, Greg Ward
#@MODIFIED   : 
#-----------------------------------------------------------------------------
sub SetupArgTables
{
   my (@args) = 
       (["Mask options", "section"],
	["-masked_input", "string", 1, \$MaskedInput,
	 "save the masked input file", "<masked_input.mnc>"],
	["-dilated_mask", "string", 1, \$DilatedMask,
	 "save a dilated mask", "<dilated_mask.mnc>"],
	["-dilation", "float", 3, \@Dilation,
	 "dilation options [default: @Dilation]", "6|26 <n_dilations>"]);
	
   (\@DefaultArgs, \@args);
}

# ------------------------------ MNI Header ----------------------------------
#@NAME       : &Initialize
#@INPUT      : 
#@OUTPUT     : 
#@RETURNS    : 
#@DESCRIPTION: Sets global variables from configuration file, parses 
#              command line, parses protocol file for more global variables,
#              finds required programs, and sets their options.  Dies on
#              any error.
#@METHOD     : 
#@GLOBALS    : site-specific: $ModelDir, $Model, $Protocol
#              preferences: $Verbose, $Execute, $Clobber, $Debug, $KeepTmp
#              protocol (data-specific preprocessing): @Subsample, @Crop,
#                 $Objective, @Blurs, $Blur
#              $ProtocolArgs
#@CALLS      : &JobControl::SetOptions
#              &JobControl::AddProgramOptions      
#              &SetupArgTables
#              &ReadConfigFile
#              &GetOptions
#              &ReadProtocol (indirectly through ParseArgs)
#              
#@CREATED    : 
#@MODIFIED   : incessantly
#-----------------------------------------------------------------------------
sub Initialize
{
   my (@all_args, @newARGV);

   $, = ' ';     # set output field separator

   # First, announce ourselves to stdout (for ease in later dissection
   # of log files) -- unless STDOUT is a tty.

   &SelfAnnounce ("STDOUT") if $Verbose && ! -t "STDOUT";

   # Set defaults for the global variables.  These can be overridden by 
   # the configuration file or the command line.

   $Verbose      = 1;
   $Execute      = 1;
   $Clobber      = 0;
   $Debug        = 0;
   $KeepTmp      = 0;

   # Specify the default pre-processing sequence -- these can be
   # overridden by the protocol file or the command line.  (The
   # protocol can in turn be specified either in the configuration
   # file or the on the command line.)

   $MaskedInput = undef;
   $DilatedMask = undef;
   @Dilation    = (26, 1);

   &CreateInfoText;

   ($defargs, $args) = &SetupArgTables;
   @all_args = (@$defargs, @$args);

   &GetOptions (\@all_args, \@ARGV, \@newARGV) || die "\n";
   if (@newARGV != 3)
   {
      warn $Usage;
      die "Incorrect number of arguments\n";
   }

   ($InputVolume, $SurfaceObject, $Mask) = @newARGV;

   # Find all the required subprograms -- everything should be on
   # the $PATH already, else we're in for a hard time portability-wise

   my(@programs) = qw(dilate_volume mincresample mincmath surface_mask2);
   RegisterPrograms (\@programs);

#   &JobControl::SetOptions (ErrorAction => 'fatal',
#                            Verbose     => $Verbose,
#                            Execute     => $Execute,
#                            Strict      => 1);

   # Add -debug, -quiet, -clobber to subprogram command lines 
   # as appropriate
   
   AddDefaultArgs("mincresample", '-quiet') unless $Verbose;
   AddDefaultArgs("mincmath", '-quiet') unless $Verbose;
   AddDefaultArgs("mincresample", '-clobber') if $Clobber;
   AddDefaultArgs("mincmath", '-clobber') if $Clobber;

   check_output_dirs ($TmpDir) if $Execute;
   
   if (! -e $InputVolume || ! -e $SurfaceObject) {
       die "Input files not found\n";
   }


#   &CheckFiles ($InputVolume, $SurfaceObject) || &Fatal;

   # Quit now if any of the output files exist and $Clobber is false

   if (-e $Mask && ! $Clobber) {
       die "$Mask exists; use -clobber to overwrite\n";
   }
   
   if (defined($DilatedMask) && -e $DilatedMask && ! $Clobber) {
       die "$DilatedMask exists; use -clobber to overwrite\n";
   }
   
   if (defined($MaskedInput) && -e $MaskedInput && ! $Clobber) {
       die "$MaskedInput exists; use -clobber to overwrite\n";
   }
}

