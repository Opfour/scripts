#!/usr/bin/perl
print "Looking for core files...\n";
#chmod 755 findcore.sh, then run ./findcore.sh
#find command looks from / for real files (no dirs, symlinks, etc.)
#named core
#change location below from '/' to 'path/to/dir' to localize
@core = `find / -type f -name core.* 2>/dev/null`;
chop (@core);
$num = @core;

if (@core) {
if ($num == 1) {
print "Found $num core file... removing...\n";
} else {
print "Found $num core files... removing...\n";
}
foreach $file (@core) {
# if we have write (-w) permission for file, we can delete it
if (-w $file) {
system("rm -rf $file");
print "Deleted $file.\n";
} else {
print "You do not have permission to delete $file!\n";
}
}
} else {
print "No core files found!\n";
}
exit(0);


