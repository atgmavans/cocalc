/*
Set the not-secure cookie

[base-url]COCALC-VERSION

to the version of the client code.  This is used by the hub-proxy server on the
backend, to decide whether or not to allow the client to connect to projects.
Basically, we do not want to allow ancient buggy clients to connect in any
way at all.
*/

const Cookies = require("js-cookie");
const { version } = require("smc-util/smc-version");
const { APP_BASE_URL } = require("./misc_page");

// We don't want this cookie to expire.  All it does is record the version of
// the code the client has loaded, and the version only goes up.
Cookies.set(`${APP_BASE_URL}cocalc_version`, version, { expires: 10000 });
