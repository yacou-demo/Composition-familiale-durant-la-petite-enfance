local originals "C:\UsersDesktop\stata8\BHPS" // OR WHATEVER THE RIGHT DIRECTORY IS.
local files: dir "`originals'" files "*hhsamp.dta" // NOTE : after C
local dir1 "C:\Users\Ebenezer\Desktop\stata8\new merge" // LOCALS ARE SAFER THAN GLOBALS

tempfile building
save `building', emptyok

foreach f of local files {
     local w = substr(`"`f'"', 1, 1)
     use `"`originals'/`f'"', clear // NOTE USE OF /, NOT \, AS SEPARATOR!!!
     keep `w'hid `w'xhwght `w'lewght `w'lrwght `w'region `w'region2
     rename `w'* * // REQUIRES RECENT STATA; IF USING VERSION 8, -renpfix `w'-
     gen wave = `"`w'"'
     sort hid wave
     append using `building'
     save `"`building'"', replace
}

label data "hhsamp1-18, long format"
save `"`dir1'/hhsamp_junk1-18.dta"', replace