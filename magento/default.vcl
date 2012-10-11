backend default {
     .host = "127.0.0.1";
     .port = "8080";
}

acl purge {
	"localhost";
	"127.0.0.1";
}

sub vcl_recv {
	if(req.request == "PURGE"){
		if(!client.ip ~ purge){
			error 405 "Purging not allowed.";
		}
		return(lookup);
	}
	if (req.restarts == 0) {
	  if (req.http.x-forwarded-for) {
	      set req.http.X-Forwarded-For =
	          req.http.X-Forwarded-For + ", " + client.ip;
	  } else {
	      set req.http.X-Forwarded-For = client.ip;
	  }
	}
	if (req.request != "GET" &&
	  req.request != "HEAD" &&
	  req.request != "PUT" &&
	  req.request != "POST" &&
	  req.request != "TRACE" &&
	  req.request != "OPTIONS" &&
	  req.request != "DELETE") {
	    return (pipe);
	}
	if (req.request != "GET" && req.request != "HEAD") {
	    return (pass);
	}
	if (req.http.Authorization) {
	    return (pass);
	}	
    if (req.url ~ "\.(jpeg|jpg|png|gif|ico|swf|js|css|gz|rar|txt|bzip|pdf|woff)(\?.*|)$") {
    	unset req.http.Cookie;
        return (lookup);
    }	
	if(req.url ~ "^(/index\.php)?/(admin|checkout|customer)"){
		return(pass);
	}
	
	if (req.http.cookie ~ "nocache(_stable)?") {
	    return (pass);
	}	
	set req.http.Cookie = regsuball(req.http.Cookie, "(^|; ) *__utm.=[^;]+;? *", "\1");
    if (req.http.Cookie == "") {
        remove req.http.Cookie;
    }	
	return(lookup);		
}

sub vcl_hit {
	if(req.request == "PURGE"){
		purge;
		error 200 "Purged.";
	}
}

sub vcl_miss {
	if(req.request == "PURGE"){
		error 200 "Not found in cache, no purging required.";
	}
}

sub vcl_deliver {
	if(obj.hits > 0){
		set resp.http.X-Varnish-Cache = "Hit ("+obj.hits+")";	
	}else{
		set resp.http.X-Varnish-Cache = "Miss";
	}
}