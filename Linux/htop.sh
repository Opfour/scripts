! [[ "$(id -u)" == "0" ]] && echo "Must be root." && exit 1
cd /usr/local/src
wget http://layer3.liquidweb.com/lantern/pkgs/htop-0.9.tar.gz
tar -xzf htop-0.9.tar.gz
cd htop-0.9
./configure && make && make install
cat <<EOF >~/.htoprc
# Beware! This file is rewritten every time htop exits.
# The parser is also very primitive, and not human-friendly.
# (I know, it's in the todo list).
fields=0 48 17 18 38 39 40 2 61 59 60 46 47 49 1
sort_key=46
sort_direction=1
hide_threads=0
hide_kernel_threads=1
hide_userland_threads=1
shadow_other_users=1
show_thread_names=1
highlight_base_name=1
highlight_megabytes=1
highlight_threads=1
tree_view=1
header_margin=0
detailed_cpu_time=1
color_scheme=5
delay=15
left_meters=AllCPUs
left_meter_modes=1
right_meters=Tasks LoadAverage Uptime CPU CPU Memory Memory Swap
right_meter_modes=2 2 2 1 2 1 2 1
EOF
htop