__NAME__ register
[if cgi mv_username]
mv_username=unique users:username [L]Username already reserved.[/L]
[else]
mv_username=required [L]Please enter username.[/L]
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
mv_password=length [either][userdb function=option name=passminlen][or]4[/either] 
mv_verify=match mv_password The specified passwords do not match.
__END__
