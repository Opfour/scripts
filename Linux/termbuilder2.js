/*

Copyright (C) 2010 Paul Hudson (http://www.tuxradar.com/termbuilder)

TermBuilder is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


To use TermBuilder, you must add it as a script to a HTML file containing at least the following HTML elements:

1) <div id="command_area"></div> - this is where the user interface will be drawn

2) <form><p><select id="add_command"></select> <input type="button" value="Add" onClick="AddCommand();" /></p></form> - this is a selection box that will contain the list of available commands

3) <div id="output_area"><textarea id="finished_command" rows="3" cols="80"></textarea></div> - this is where the final command will be printed

With those three in place, include this file ***beneath*** those elements on your page, like this:

<script type="text/javascript" src="termbuilder.js"></script>

 
*/

/* called when the Add button is clicked to add a new command to the list */
function AddCommand() {
	++unique_id; // every command <div> has its own ID number for easier reading
	type = command_types[add_command.selectedIndex];

	newdiv = document.createElement('div');
	newdiv.id = 'command_div' + unique_id;
	newdiv.setAttribute('name', add_command.selectedIndex);
	newdiv.innerHTML = '<div style="float: right; padding-top: 4px; padding-right: 5px; color: white;"><a onclick="MoveCommandUp(' + unique_id + ')">Up</a> / <a onclick="MoveCommandDown(' + unique_id + ')">Down</a> / <a onclick="DeleteCommand(' + unique_id + ')">Delete</a></div> <h2>' + type.FriendlyName + '</h2><span>' + type.Html + '</span>';

	// we lazily attach JavaScript code to things like OnKeyUp; this saves having to hard-code the events
	AttachChangedEvents(newdiv);

	// if we already have a commend, we need to include a "then..." before this one to show the chain
	if (command_area.childNodes.length > 0) {
		newp = document.createElement('p');
		newp.setAttribute('class', 'then');
		newp.setAttribute('align', 'center');
		newp.innerHTML = 'then...';
		command_area.appendChild(newp);
	}

	command_area.appendChild(newdiv);
	
	FlattenCommand();
}

/* called when a user moves a command up in the list */
function MoveCommandUp(id) {
	element = document.getElementById('command_div' + id);
	element_pos = IndexOfElement(element.parentNode, element);
	if (element_pos == 0) return;
	
	old_node = element.parentNode.childNodes[element_pos - 2];
	old_then = element.parentNode.childNodes[element_pos - 1];

	element.parentNode.replaceChild(element, element.parentNode.childNodes[element_pos - 2]);
	element.parentNode.insertBefore(old_node, old_then.nextSibling);
	
	FlattenCommand();
}

/* called when a user moves a command down in the list */
function MoveCommandDown(id) {
	element = document.getElementById('command_div' + id);
	element_pos = IndexOfElement(element.parentNode, element);
	if (element_pos == element.parentNode.childNodes.length - 1) return;
	
	old_node = element.parentNode.childNodes[element_pos + 2];
	old_then = element.parentNode.childNodes[element_pos + 1];

	element.parentNode.replaceChild(element, element.parentNode.childNodes[element_pos + 2]);
	element.parentNode.insertBefore(old_node, old_then);
	
	FlattenCommand();
}

/* called when a user deletes command in the list */
function DeleteCommand(id) {
	element = document.getElementById('command_div' + id);
	element_pos = IndexOfElement(element.parentNode, element);
	
	delete_then = true;
	
	if (element_pos == element.parentNode.childNodes.length - 1) delete_then = false;
	if (element.parentNode.childNodes.length == 0) delete_then = false;
	
	if (delete_then) element.parentNode.removeChild(element.nextSibling);
	element.parentNode.removeChild(element);
	
	FlattenCommand();
}

/* find a child element by ID */
function IndexOfElement(parent, child) {
	for (i = 0; i < parent.childNodes.length; ++i) {
		if (parent.childNodes[i].id == child.id) return i;
	}

	return -1;
}

/* convert the list of <div>s into a Unix command */
function FlattenCommand() {
	flattened_command = '';

	divs = command_area.getElementsByTagName('div');

	for (i = 0; i < divs.length; ++i) {
		div = divs[i];
		
		current_command = div.getAttribute('name');
		if (current_command == null) continue;

		add_to_command = command_types[current_command].Flatten(div);

		if (add_to_command.length > 0) {
			if (flattened_command.length > 0) {
				if (command_types[current_command].PrefixWith.length > 0) {
					flattened_command += ' ' + command_types[current_command].PrefixWith + ' ';
				} else {
					flattened_command += ' ';
				}
			}
			
			flattened_command += add_to_command;
		}
	}

	finished_command.value = flattened_command;

	if (flattened_command.length > 0) {
		output_area.style.display = '';
	} else {
		output_area.style.display = 'none';
	}
	
	if (command_area.childNodes.length == 0) {
		command_area.style.display = 'none';	
	} else {
		command_area.style.display = '';
	}
}

/* lazily monitor for interesting events so we can auto-flatten the command */
function AttachChangedEvents(element) {
	inputs = element.getElementsByTagName('input');

	for (i = 0; i < inputs.length; ++i) {
		inputs[i].onkeyup = FlattenCommand;
		inputs[i].onchange = FlattenCommand;
	}

	selects = element.getElementsByTagName('select');
	for (i = 0; i < selects.length; ++i) {
		selects[i].onchange = FlattenCommand;
	}
}

/* neat little chunk of XPath that finds a particular child element */
function GetElement(element, name) {
	return document.evaluate('.//*[@name="' + name + '"]', element, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
}

function ShowHelp(message) {
	alert(message);
}

unique_id = 0;

var add_command = document.getElementById('add_command');
var command_area = document.getElementById('command_area');
var output_area = document.getElementById('output_area');
var finished_command = document.getElementById('finished_command');
var command_html = '';

/* all our commands are defined in these objects */
function CommandType() {
	this.FriendlyName = '';
	this.CommandName = '';
	this.PrefixWith = '|';
	this.MustBeFirst = false;
}

var command_types = Array();

comm = new CommandType();
comm.FriendlyName ='Count input words or lines';
comm.Html = '<p>Count: <select name="what"><option value="0">letters</option> <option value="1" selected="selected">lines</option> <option value="2">words</option> </select> <sup><a onClick="javascript:ShowHelp(\'Many of the commands available here work with lots of lines of data, eg when you list the files in a directory they are returned one per line. As a result, if you want to count any of this data, you will want to use the lines option here.\');">?</a></sup> </p>';
comm.Flatten =
	function(element) {
		what = GetElement(element, 'what');
		if (what.value == 0) {
			return 'wc -c';
		} else if (what.value == 1) {
			return 'wc -l';
		} else {
			return 'wc -w';
		}
	}
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'List all running programs';
comm.Html = '';
comm.Flatten = 
	function(element) {
		return 'ps aux';
	}
comm.MustBeFirst = true;
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'List files with certain attributes';
comm.Html = '<p>Start from: <select name="start_dir"> <option value="0">the current directory</option> <option value="1">your home directory</option> <option value="2">the root directory</option> <option value="3">somewhere else</option></select> <sup><a onClick="javascript:ShowHelp(\'This is the root directory for the search. Only files that exist within the current folder (or its subfolders, if you enable subdirectory searching) will be searched for files.\');">?</a></sup> <input type="checkbox" name="recurse" /> Search in subdirectories <sup><a onClick="javascript:ShowHelp(\'Without this option, only files in the current directory will be found. If you enable it, all subdirectories will be searched, as well as all their subdirectories, and so on.\');">?</a></sup></p> <p>Search for filename: <input type="text" name="filename" /> <input type="checkbox" name="ignore_case" /> Ignore case <sup><a onClick="javascript:ShowHelp(\'If you are looking for a file of a particular name, enter it here. If you don\t select Ignore Case then you will need to type the exact filename, ie searching for SOMEFILE will not find somefile.\');">?</a></sup></p> <p>Only list files of size: <input type="text" name="file_size" /> <select name="size_type" /> <option value="0">KB</option> <option value="1">MB</option> <option value="2">GB</option></select> <select name="size_modifier" /> <option value="0">or lower</option> <option value="1">or higher</option></select> <sup><a onClick="javascript:ShowHelp(\'If you want to find only files of a particular size, for example if you want to delete files from your hard drive that take up lots of space, use these settings to narrow down the search.\');">?</a></sup> </p> <p>Owned by user name: <input type="text" name="user"> <sup><a onClick="javascript:ShowHelp(\'If you know that a particular user created a file, you can search for it using their username.\');">?</a></sup></p>';
comm.Flatten =
	function(element) {
		start_dir = GetElement(element, 'start_dir');
		recurse = GetElement(element, 'recurse');
		filename = GetElement(element, 'filename');
		ignore_case = GetElement(element, 'ignore_case');
		file_size = GetElement(element, 'file_size');
		size_type = GetElement(element, 'size_type');
		size_modifier = GetElement(element, 'size_modifier');
		user = GetElement(element, 'user');

		params = '';
		
		switch (start_dir.selectedIndex) {
			case 0:
				params += ' .';
				break;
			case 1:
				params += ' ~';
				break;
			case 2:
				params += ' /';
				break;
			case 3:
				params += ' /path/to/your/directory';
				break;
		}

		if (!recurse.checked) params += ' maxdepth 1';

		if (filename.value.length > 0) {
			if (ignore_case.checked) {
				params += ' -iname "' + filename.value + '"';
			} else {
				params += ' -name "' + filename.value + '"';
			}
		}

		if (file_size.value.length > 0) {
			params += ' -size ';

			if (size_modifier.selectedIndex == 0) {
				params += '-';
			} else {
				params += '+';
			}

			params += file_size.value;

			if (size_type.selectedIndex == 0) {
				params += 'k';
			} else if (size_type.selectedIndex == 1) {
				params += 'M';
			} else {
				params += 'G';
			}
		}

		if (user.value.length > 0) {
			params += ' -user ' + user.value
		}

		return 'find' + params;
	}
comm.MustBeFirst = true;
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'List the contents of a directory';
comm.Html = '<p>Matching name: <input type="text" name="search_text" /> <sup><a onClick="javascript:ShowHelp(\'You can use wildcards here if you want. For example, foo.* will match foo.txt, foo.sh, etc. \');">?</a></sup></p> <p>Sort order: <select name="sort_order"><option value="0">Alphabetical, A-Z</option> <option value="1">Alphabetical, Z-A</option> <option value="2">File size, smallest first</option> <option value="3">File size, largest first</option> <option value="4">Date modified, oldest first</option> <option value="5">Date modified, newest first</option></select> <sup><a onClick="javascript:ShowHelp(\'Although TermBuilder can give you a separate sort command, sorting your data here is smarter because it can be sorted by things such as file size or modification date.\');">?</a></sup> </p> <p><input type="checkbox" name="show_hidden" /> Show hidden files too <sup><a onClick="javascript:ShowHelp(\'When this is checked, your command will return dotfiles such as .htaccess or .gnome2. It will not, however, return the special files \'.\' and \'..\'.\');">?</a></sup></p>';
comm.Flatten =
	function(element) {
		search_text = GetElement(element, 'search_text');
		sort_order = GetElement(element, 'sort_order');
		show_hidden = GetElement(element, 'show_hidden');

		params = '';

		if (show_hidden.checked) params = ' -a';

		switch (sort_order.selectedIndex) {
			case 0: // alphabetical A-Z; the default for ls
				break;

			case 1: // alphabetical, Z-A
				params += ' -r';
				break;

			case 2: // file size, smallest first
				params += ' -Sr';
				break;

			case 3: // file size, largest first
				params += ' -S';
				break;

			case 4: // date modified, oldest first
				params += ' -tR';
				break;

			case 5: // date modified, newest first
				params += ' -t';
				break;
		}

		if (search_text.value.length == 0) {
			params += ' *';
		} else {
			params += ' ' + search_text.value;
		}

		return 'ls -d' + params;
	}
comm.MustBeFirst = true;
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'Print part of the contents of files';
comm.Html = '<p>Filename(s): <input type="text" name="filename" /> <sup><a onClick="javascript:ShowHelp(\'You can use wildcards here if you want. For example, foo.* will match foo.txt, foo.sh, etc. \');">?</a></sup></p> <p>Number of lines to print: <input type="text" name="number_of_lines" /> <sup><a onClick="javascript:ShowHelp(\'The number you enter here will dictate how many of the lines from the file will be printed. The default is 10.\');">?</a></sup></p> <p>Read from: <select name="read_from"><option value="0">Top of file</option> <option value="1">Bottom of file</option></select> <sup><a onClick="javascript:ShowHelp(\'Printing 20 lines from the top of the file will print the first 20 lines; printing 20 from the bottom of the file will print the last 20.\');">?</a></sup></p>';
comm.Flatten =
	function(element) {
		filename = GetElement(element, 'filename');
		number_of_lines = GetElement(element, 'number_of_lines');
		read_from = GetElement(element, 'read_from');

		if (filename.value.length == 0) return '';

		params = '';

		if (number_of_lines.value.length > 0) params = '-n ' + number_of_lines.value + ' ';

		if (read_from.selectedIndex == 0) {
			// top of file
			return 'head -q ' + params + filename.value;
		} else {
			// bottom of file
			return 'tail -q ' + params + filename.value;
		}

	}
comm.MustBeFirst = true;
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'Print part of the contents of input';
comm.Html = '<p>Number of lines to print: <input type="text" name="number_of_lines" /> <sup><a onClick="javascript:ShowHelp(\'The number you enter here will dictate how many lines from the input will be printed. The default is 10.\');">?</a></sup> </p> <p>Read from: <select name="read_from"><option value="0">Top of input</option> <option value="1">Bottom of input</option></select> <sup><a onClick="javascript:ShowHelp(\'Printing 20 lines from the top of the input will print the first 20 lines; printing 20 from the bottom will print the last 20.\');">?</a></sup></p>';
comm.Flatten =
	function(element) {
		number_of_lines = GetElement(element, 'number_of_lines');
		read_from = GetElement(element, 'read_from');

		params = '';

		if (number_of_lines.value.length > 0) params = '-n ' + number_of_lines.value + ' ';

		if (read_from.selectedIndex == 0) {
			// top of input
			return 'head ' + params;
		} else {
			// bottom of input
			return 'tail ' + params;
		}

	}
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'Print the contents of files';
comm.Html = '<p>Matching filename: <input type="text" name="filename" /> <sup><a onClick="javascript:ShowHelp(\'You can use wildcards here if you want. For example, foo.* will match foo.txt, foo.sh, etc. \');">?</a></sup></p> <p><input type="checkbox" name="line_numbers" /> Add line numbers <sup><a onClick="javascript:ShowHelp(\'With this option enabled, every line will have its line number printed next to it, which is great for editing code files or configuration files.\');">?</a></sup> </p>';
comm.Flatten = 
	function(element) {
		filename = GetElement(element, 'filename');
		line_numbers = GetElement(element, 'line_numbers');
		
		if (line_numbers.checked) {
			return 'cat -n ' + filename.value;
		} else {
			return 'cat ' + filename.value;
		}
	}
comm.MustBeFirst = true;
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'Print part of each input line';
comm.Html = '<p>Character range to display: <input type="text" name="range" /> <sup><a onClick="javascript:ShowHelp(\'Specify your range using two numbers separated by a dash. For example, 1-3 will print the first three characters. If you use 10- it will print the 10th character up until the end of each line.\');">?</a></sup></p>';
comm.Flatten =
	function(element) {
		range = GetElement(element, 'range');

		if (range.value.length > 0) {
			return 'cut -c ' + range.value;
		} else {
			return '';
		}
	}
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'Remove duplicate adjacent lines';
comm.Html = '<p class="description">Note: if you want to strip out all duplicates in your input, add a sort command before this.</p> <p><input type="checkbox" name="ignore_case" /> Ignore case <sup><a onClick="javascript:ShowHelp(\'If you choose not to ignore case, FOO and Foo will not be considered duplicates.\');">?</a></sup></p> ';
comm.Flatten =
	function(element) {
		ignore_case = GetElement(element, 'ignore_case');

		if (ignore_case.checked) {
			return 'uniq -i';
		} else {
			return 'uniq';
		}
	}
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'Save output to a file';
comm.Html = '<p>Filename: <input type="text" name="filename" /> <sup><a onClick="javascript:ShowHelp(\'You may not use wildcards here - you must specify a normal file name to which you have write privileges.\');">?</a></sup></p> <p><input type="checkbox" name="append" /> Add the output to the end of the file\'s existing contents <sup><a onClick="javascript:ShowHelp(\'When this box is unchecked, any existing file with the same name will be overwritten; when this box is checked, the new text is added to the bottom of the old.\');">?</a></sup></p>';
comm.Flatten =
	function(element) {
		filename = GetElement(element, 'filename');
		append = GetElement(element, 'append');

		if (filename.value.length > 0) {
			if (append.checked) {
				return '>> ' + filename.value;
			} else {
				return '> ' + filename.value;
			}
		}
		
		return '';
	}
comm.PrefixWith = '';
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'Search for text in files';
comm.Html = '<p>Search for text: <input type="text" name="search_text" /> <sup><a onClick="javascript:ShowHelp(\'This is the text you want to find in files. For example, if you wrote a letter to your father and do not remember where it is, searching for Dad with Ignore Case turned on is a good way to find it.\');">?</a></sup></p> <p>Files or directories to search: <input type="text" name="search" /> <sup><a onClick="javascript:ShowHelp(\'You can use wildcards here if you want. For example, foo.* will match foo.txt, foo.sh, etc. \');">?</a></sup></p> <p><input type="checkbox" name="ignore_case" /> Ignore case <sup><a onClick="javascript:ShowHelp(\'When checked, matching searches will be returned even if the letter case is different, eg DAD and Dad.\');">?</a></sup></p> <p><input type="checkbox" name="invert" /> Return non-matching lines <sup><a onClick="javascript:ShowHelp(\'When this box is checked, the search does the opposite of normal. For example, if you search for Cat normally, this search will return all files with the word Cat in. When this box is checked, this search will return all files that do not have the word Cat in.\');">?</a></sup></p> <p><input type="checkbox" name="recurse" /> Search in subdirectories <sup><a onClick="javascript:ShowHelp(\'When this box is checked, this search will search the current directory and all subdirectories.\');">?</a></sup></p> ';
comm.Flatten =
	function(element) {
		search_text = GetElement(element, 'search_text');
		search = GetElement(element, 'search');
		ignore_case = GetElement(element, 'ignore_case');
		invert = GetElement(element, 'invert');
		recurse = GetElement(element, 'recurse');

		if (search_text.value.length == 0) return '';

		if (search.value.length > 0) {
			search_in = search.value;
		} else {
			search_in = '*';
		}

		params = '';
		if (ignore_case.checked) params += ' -i';
		if (invert.checked) params += ' -v';
		if (recurse.checked) params += ' -r';

		return 'grep' + params + ' "' + search_text.value + '" ' + search_in;
	}
comm.MustBeFirst = true;
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'Search for text in input';
comm.Html = '<p>Search for text: <input type="text" name="search_text" /> <sup><a onClick="javascript:ShowHelp(\'This is the text you want to find in files. For example, if you wrote a letter to your father and do not remember where it is, searching for Dad with Ignore Case turned on is a good way to find it.\');">?</a></sup></p> <p><input type="checkbox" name="ignore_case" /> Ignore case <sup><a onClick="javascript:ShowHelp(\'When checked, matching searches will be returned even if the letter case is different, eg DAD and Dad.\');">?</a></sup></p> <p><input type="checkbox" name="invert" /> Return non-matching lines <sup><a onClick="javascript:ShowHelp(\'When this box is checked, the search does the opposite of normal. For example, if you search for Cat normally, this search will return all files with the word Cat in. When this box is checked, this search will return all files that do not have the word Cat in.\');">?</a></sup></p>';
comm.Flatten = 
	function(element) {
		search_text = GetElement(element, 'search_text');
		ignore_case = GetElement(element, 'ignore_case');
		invert = GetElement(element, 'invert');

		if (search_text.value.length == 0) return '';

		params = '';
		if (ignore_case.checked) params += ' -i';
		if (invert.checked) params += ' -v';

		return 'grep' + params + ' "' + search_text.value + '"';
	}
command_types.push(comm);

comm = new CommandType();
comm.FriendlyName = 'Sort input lines';
comm.Html = '<p><input type="checkbox" name="reverse" /> Reverse the sort order <sup><a onClick="javascript:ShowHelp(\'By default, this will sort alphabetically from Z to A. When combined with the Sort Numerically option, it will sort form highest to lowest.\');">?</a></sup></p> <p><input type="checkbox" name="numeric" /> Sort numerically <sup><a onClick="javascript:ShowHelp(\'When this box is checked, each line in the input wil be treated like a number, meaning that you will not see sorting results such as 1, 10, 11, 2, 3.\');">?</a></sup></p>';
comm.Flatten =
	function(element) {
		reverse = GetElement(element, 'reverse');
		numeric = GetElement(element, 'numeric');

		params = '';
		if (reverse.checked) params += ' -r';
		if (numeric.checked) params += ' -n';

		return 'sort' + params;
	}
command_types.push(comm);

/* generate the list of commands for the Add Command select box */
for (i = 0; i < command_types.length; ++i) {
	option = document.createElement('option');
	option.value = i;
	
	if (command_types[i].MustBeFirst) {
		option.text = '* ' + command_types[i].FriendlyName;
	} else {
		option.text = command_types[i].FriendlyName;		
	}

	add_command.options.add(option);
}

