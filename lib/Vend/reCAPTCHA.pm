# Vend::reCAPTCHA - reCAPTCHA generation for Interchange
#
# Copyright (C) 2013 Stefan Hornburg (Racke) <racke@linuxia.de>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

package Vend::reCAPTCHA;

use strict;
use warnings;

use Captcha::reCAPTCHA;

=head1 NAME

Vend::reCAPTCHA - Interchange 5 implementation of reCAPTCHA

=head1 DESCRIPTION

Display the reCAPTCHA widget in your form:

    [recaptcha get_html]

=head1 VARIABLES

=over 4

=item RECAPTCHA_PUBLIC_KEY

Your public key for reCAPTCHA API (mandatory).

=item RECAPTCHA_PRIVATE_KEY

Your private key for reCAPTCHA API (mandatory).

=item RECAPTCHA_THEME

Select your recaptcha theme from the four standard themes:
red (default), white, blackglass, clean.

See L<https://developers.google.com/recaptcha/docs/customization#Standard_Themes>.

=back

=head1 ATTENTION

Check that you haven't placed your input <form> in a <table>
(the table should be in the form) in your input code.

L<https://code.google.com/p/recaptcha/wiki/FAQ#I_keep_getting_%22incorrect-captcha-sol%22_even_though_I&%23>

=cut

our %recaptcha_vars = (public_key => {required => 1,
                                      option => 0,
                                     },
                       private_key => {required => 1,
                                      option => 0,
                                      },
                       theme => {required => 0,
                                 option => 1,
                                },
                       lang => {required => 0,
                                option => 1,
                               },
                       custom_theme_widget => {required => 0,
                                               option => 1,
                                              },
                       tabindex => {required => 0,
                                    option => 1,
                                   },
                       );

# define [recaptcha] tag

Vend::Config::parse_tag('UserTag', 'recaptcha Order function');
Vend::Config::parse_tag('UserTag', 'recaptcha AddAttr');
Vend::Config::parse_tag('UserTag', 'recaptcha MapRoutine Vend::reCAPTCHA::recaptcha');

# [recaptcha] function

sub recaptcha {
    my ($function, $opt) = @_;

    my $recaptcha = recaptcha_object();

    my $var_ref = recaptcha_variables();

    if ($function eq 'get_html') {
        return $recaptcha->get_html($var_ref->{public_key},
                                    undef,
                                    # use SSL based API ?
                                    $CGI::secure,
                                    recaptcha_options({%{$var_ref}, %$opt}),
                                    );
    }
    elsif ($function eq 'check_answer') {
        my @values = ($var_ref->{private_key},
                      $Vend::Session->{ohost},
                      $CGI::values{recaptcha_challenge_field},
                      $CGI::values{recaptcha_response_field},
                     );

        my $result = $recaptcha->check_answer(@values);

        return $result->{is_valid};
    }

    die "[recaptcha]: Unsupported function $function.";
}

sub recaptcha_object {
    return Captcha::reCAPTCHA->new;
}

sub recaptcha_options {
    my ($input_ref) = @_;
    my (%options);

    for my $name (keys %recaptcha_vars) {
        next if ! $recaptcha_vars{$name}->{option};
        next if ! exists $input_ref->{$name};

        $options{$name} = $input_ref->{$name};
    }

    return \%options;
}

sub recaptcha_variables {
    my (%our_vars, $full_name);

    for my $name (keys %recaptcha_vars) {
        $full_name = "RECAPTCHA_" . uc($name);

        if ($::Variable->{$full_name}) {
            $our_vars{$name} = $::Variable->{$full_name};
        }
        elsif ($recaptcha_vars{$name}->{required}) {
            die "[recaptcha]: Missing variable $full_name.";
        }
    }

    return \%our_vars;
}

1;
