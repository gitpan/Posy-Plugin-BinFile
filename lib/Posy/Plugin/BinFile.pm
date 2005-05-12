package Posy::Plugin::BinFile;
use strict;

=head1 NAME

Posy::Plugin::BinFile - Posy plugin to serve (binary) non-entry files.

=head1 VERSION

This describes version B<0.62> of Posy::Plugin::BinFile.

=cut

our $VERSION = '0.62';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::FileStats
	Posy::Plugin::BinFile));

=head1 DESCRIPTION

This plugin renders non-entry files (the 'file' path-type), giving the
correct MIME-type for the requested file -- if the file exists in the
data directory.

This allows you to (a) integrate existing web-pages into a Posy site
by putting them into the data_dir(*) (b) include image files alongside
entry files by putting them in the same directory (and reference them with
relative paths just as you would normally).

This depends on the FileStats plugin for the MIME-type information for
the files.

(*) Note that since Posy recognises and processes '.html' and '.txt' files
by default, if you want such files to be processed as raw files and not
as Posy-entry files, you need to give them different extensions.

This plugin replaces a number of methods, adding in code for dealing with
'file' path-type files.  There is no need to add extra actions.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

=over

=item B<static_file_default_type>

What is the default MIME type for a file when it can't determine
the type?
(default: "text/plain")

=back

=cut

=head1 OBJECT METHODS

Documentation for developers and those wishing to write plugins.

=head2 init

Do some initialization; make sure that default config values are set.

=cut
sub init {
    my $self = shift;
    $self->SUPER::init();

    # set defaults
    $self->{config}->{static_file_default_type} = "text/plain"
	if (!defined $self->{config}->{static_file_default_type});
} # init

=head1 Flow Action Methods

Methods implementing actions.

=head2 content_type

$self->content_type($flow_state);

Set the content_type content in $flow_state->{content_type}

If the path-type is 'file', this skips all the actions up to 'render_page'.

=cut
sub content_type {
    my $self = shift;
    my $flow_state = shift;

    if ($self->{path}->{type} eq 'file')
    {
	my %config = $self->get_config('content_type');
	while (my ($key, $val) = each %config)
	{
	    $self->{config}->{$key} = $val;
	}
	# get the mime type
	$flow_state->{content_type} =
	    $self->{file_stats}->
		{$self->{path}->{data_file}}->{mime_type};
	if ($flow_state->{content_type} =~ m#^x-system/x-unix.*executable.*perl#)
	{
	    $flow_state->{content_type} = 'application/x-perl';
	}
	# check for a i-dont-know-the-type content_type
	if (!defined $flow_state->{content_type}
	    or $flow_state->{content_type} =~ m#^x-system/x-unix.*symbolic link#
	    or $flow_state->{content_type} =~ m#^application/x-not-regular-file#)
	{
	    $flow_state->{content_type} = $self->{config}->{static_file_default_type};
	}
	
	$self->debug(1, "content_type=$flow_state->{content_type}");
	# now, skip all the actions until we get to 'render_page'
	while (@{$self->{actions}}
	    and $self->{actions}->[0] ne 'render_page')
	{
	    my $action = shift @{$self->{actions}};
	}
    }
    else
    {
	$self->SUPER::content_type($flow_state);
    }
    1;	
} # content_type

=head2 render_page

$self->render_page($flow_state);

Put the page together by pasting together 
its parts in the $flow_state hash
and print it (either to a file, or to STDOUT).
If printing to a file, don't print content_type

If rendering a 'file' just give the content-type and the file data.

=cut
sub render_page {
    my $self = shift;
    my $flow_state = shift;

    if ($self->{path}->{type} eq 'file')
    {
	# read in the raw file data and render it
	my $data;
	my $fullname = $self->{path}->{data_file};
	{
	    my $fh;
	    local $/;
	    if (-r $fullname
		and open $fh, $fullname) 
	    {
		$data = <$fh>;
		close($fh);
	    }
	    else # error
	    {
		warn "Could not open $fullname";
	    }
	}

	if (defined $self->{outfile}
	    and $self->{outfile}) # print to a file
	{
	    my $fh;
	    if (open $fh, ">$self->{outfile}")
	    {
		print $fh $data;
		close($fh);
	    }
	}
	else {
	    $self->print_header(content_type=>$flow_state->{content_type});
	    print $data;
	}
    }
    else
    {
	$self->SUPER::render_page($flow_state);
    }
    1;	
} # render_page

=head1 INSTALLATION

Installation needs will vary depending on the particular setup a person
has.

=head2 Administrator, Automatic

If you are the administrator of the system, then the dead simple method of
installing the modules is to use the CPAN or CPANPLUS system.

    cpanp -i Posy::Plugin::BinFile

This will install this plugin in the usual places where modules get
installed when one is using CPAN(PLUS).

=head2 Administrator, By Hand

If you are the administrator of the system, but don't wish to use the
CPAN(PLUS) method, then this is for you.  Take the *.tar.gz file
and untar it in a suitable directory.

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

=head2 User With Shell Access

If you are a user on a system, and don't have root/administrator access,
you need to install Posy somewhere other than the default place (since you
don't have access to it).  However, if you have shell access to the system,
then you can install it in your home directory.

Say your home directory is "/home/fred", and you want to install the
modules into a subdirectory called "perl".

Download the *.tar.gz file and untar it in a suitable directory.

    perl Build.PL --install_base /home/fred/perl
    ./Build
    ./Build test
    ./Build install

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the scripts (posy_one,
posy_static).

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 REQUIRES

    Posy
    Posy::Core
    Posy::Plugin::FileStats

    Test::More

=head1 SEE ALSO

perl(1).
Posy

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004-2005 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::BinFile
__END__
