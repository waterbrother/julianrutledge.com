<div class="content">
		<h2>9/21/2014 - Email, Security</h2>
		<p>For the last week or so, the server has been taking a pounding from some stupid script kiddies.
		I don't know if they're working in conjunction or seperately; all I know is that my logs are full of attempts to brute force ssh access.
		I'm very happy that all signs indicate that the server has not been breached, but I realized that I've been pretty lax about security and need to tighten up the ship.
		I've locked down ssh: denying root access, created a user log in account with the sole purpose of su'ing to root if needed. 
		I ran nmap to assess what vulnerabilites might exist and then installed fail2ban and Samhain to make sure attacks are actively blocked and any file system changes are recorded. 
		At this point, I'm very confident that my server is secure. 
		
		In other news, I've gotten email up and running, and julian@julianrutledge.com will point to my email hosting site. All is well on the eastern front, nothing more to report. 
		Maybe I'll have some time to post some philosphising later. Good night, internet.</p>
</div>
