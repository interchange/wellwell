__NAME__ register
[if cgi username]
username=unique users:username [L]Username already reserved.[/L]
[else]
username=required [L]Please enter username.[/L]
[/else]
[/if]
[if cgi email]
email=email_only
&and
email=unique users:email [L]Email address already reserved.[/L]
[else]
email=required [L]Please enter email address.[/L]
[/else]
[/if]
password=length [either][userdb function=option name=passminlen][or]4[/either] 
password_verify=match password The specified passwords do not match.
__END__
