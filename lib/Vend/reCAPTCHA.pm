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

use Captcha::reCAPTCHA;

=head1 NAME

Vend::reCAPTCHA - Interchange 5 implementation of reCAPTCHA

=head1 ATTENTION

Check that you haven't placed your input <form> in a <table>
(the table should be in the form) in your input code.

L<https://code.google.com/p/recaptcha/wiki/FAQ#I_keep_getting_%22incorrect-captcha-sol%22_even_though_I&%23>

=cut

# define [recaptcha] tag

Vend::Config::parse_tag('UserTag', 'recaptcha Order function');
Vend::Config::parse_tag('UserTag', 'recaptcha AddAttr');
Vend::Config::parse_tag('UserTag', 'recaptcha MapRoutine Vend::reCAPTCHA::recaptcha');

# [recaptcha] function

sub recaptcha {
    my ($function) = @_;

    my $recaptcha = recaptcha_object();

    $var_ref = recaptcha_variables();

    if ($function eq 'get_html') {
        return $recaptcha->get_html($var_ref->{public_key});
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

sub recaptcha_variables {
    my (%vars, $full_name);

    for my $name ('public_key', 'private_key') {
        $full_name = "RECAPTCHA_" . uc($name);

        if ($::Variable->{$full_name}) {
            $vars{$name} = $::Variable->{$full_name};
        }
        else {
            die "[recaptcha]: Missing variable $full_name.";
        }
    }

    return \%vars;
}

1;
