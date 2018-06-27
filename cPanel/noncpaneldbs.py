#!/usr/bin/env python
# acarlsonlynch 2014

import fileinput
import getopt
import os
import shutil
import subprocess
import sys
import time

if sys.version_info >= (3,0):
    global raw_input
    raw_input = input

startTime = time.time()

class getDbs:
    def __init__(self):
        self.verbose = False
        self.silent = False
        self.force = False
        self.interactive = False

        self.linuxCheck = 1
        self.cpanelCheck = 1
        self.dumpdirCheck = 1
        
        self.cpanelDbs = list()
        self.localDbs = list()
        self.nonCpanelDbs = list()
        
        self.dbDumpPath = "/home/temp/dbdumps/"
        self.grantsFile = "grants.sql"
        self.cpDbYamlPath = "/var/cpanel/databases/"
        self.logaholicPrefix="logaholicDB_"
        self.cpExcludeDbs = ["cphulkd",
            "eximstats",
            "horde",
            "information_schema",
            "leechprotect",
            "modsec",
            "mysql",
            "performance_schema",
            "roundcube",
            "whmxfer"]


    def askQuestions(self, arg):
        if (arg == "dumpPath") or (arg == "all"):
            newPath = raw_input("Where would you like to store the database dumps? [%s]: " %self.dbDumpPath).strip()
            if not newPath == "":
                if not newPath.endswith("/"):
                    newPath = newPath + "/"
                self.dbDumpPath = newPath
        if (arg == "grantsFile") or (arg == "all"):
            newFile = raw_input("What would you like the grants file to be called? [%s]: " %self.grantsFile).strip()
            if not newFile == "":
               self.grantsFile = newFile
        return


    def doChecks(self):			#Check that we're on Linux, check for cPanel if needed check there's nothing in the way where we want to write data
        if self.linuxCheck == 1:
            if not sys.platform.startswith('linux'):
                print("Why aren't we running on Linux. This program is not happy. Goodbye.")
                sys.exit()
        if self.cpanelCheck == 1:
            if not os.path.isdir(self.cpDbYamlPath):
                print("cPanel YAML path %s doesn't exist. Is this a cPanel server? This program is not happy. Goodbye friend :(" %self.cpDbYamlPath)
                sys.exit()
        if self.dumpdirCheck == 1:
            if os.path.isdir(self.dbDumpPath):
                if not self.force:
                    if yesno(message="%s exists already. Would you like to move it out of the way? (y/n): " %self.dbDumpPath) == 1:
                        self.moveDumpPath()
                    elif yesno(message="Okay, are you sure you want to just write to %s potentially overwriting existing data? (y/n): " %self.dbDumpPath) == 0:
                        print("Exiting to let you make up your mind")
                        sys.exit()
                else:
                    self.moveDumpPath()
        return


    def moveDumpPath(self):
        newLoc=self.dbDumpPath.rstrip("/")+"."+str(startTime)
        if not self.silent:
            print("\nMoving %s to %s..." %(self.dbDumpPath, newLoc))
        try:
            shutil.move(self.dbDumpPath, newLoc)
        except:
            print("Error moving %s to %s. Something has gone wrong. This program is not happy." %(self.dbDumpPath, newLoc))
        return



    def addCpDefaults(self, dbList):		#Probably doesn't need it's own function. Adds database names listed in cpExcludeDbs to the end of a list
        for db in self.cpExcludeDbs:
            dbList.append(db)
        return dbList


    def getCpDbs(self):				#Gets the databases owned by cPanel out of the YAML files without us having to install PyYAML Calls addCpDefaults to add on known default cPanel databases
        yamlList = list()
        startRead = 0
        myDb = ""
        dbList = list()

        for file in os.listdir(self.cpDbYamlPath):
            if file.endswith(".yaml") and not "grants_" in file:
                yamlList.append(self.cpDbYamlPath+file)
        for line in fileinput.input(yamlList):
            if "dbusers:" in line and startRead==1:
                startRead = 2
            if "MYSQL:" in line and startRead==2:
                startRead = 0
            if startRead==1:
                myDb = line.split(':', 1)[0]
                if not myDb=="\n":
                    dbList.append(myDb.strip())
            if "dbs:" in line and startRead==0:
                startRead = 1
        dbList = self.addCpDefaults(dbList)
        dbList.sort()
        self.cpanelDbs = dbList
        if self.verbose:
            print("\nFound cPanel and system DBs:\n")
            listPrint(self.cpanelDbs)
            print("\n\n")
        return


    def mysqlCommand(self, command):		#Uses the mysql command line utility linux style so that we can get things done without installing a python MySQL driver
        p = subprocess.Popen(['mysql', '-Ns', '-e', command], stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
        out, err = p.communicate()
        if not err=="":
            print("PANIC! IT'S AN ERROR" + err)
            sys.exit()
        else:
            return out


    def getLocalDbs(self):			#Gets all local DBs by running the MySQL command "show databases" and adding the results to a list
        dbList = list()

        dbs = self.mysqlCommand("show databases")
        for db in dbs.split():
            dbList.append(db)    
        dbList.sort()
        self.localDbs = dbList
        if self.verbose:
            print("\nFound Local DBs:\n")
            listPrint(self.localDbs)
            print("\n\n")
        return


    def getNonCpanelDbs(self, localDbs, cpDbs):	#Compares a list of local databases and databases owned by cPanel also omits the logaholic dbs by what's in the logaholicPrefix variable
        nonCpDbs = list()
        if self.verbose:
            print("This is where we are ommitting the logaholic databases with prefix = %s from our non-cpanel databases list.\n\n" %self.logaholicPrefix)
        for db in localDbs:
            if db not in cpDbs and self.logaholicPrefix not in db:
                nonCpDbs.append(db)
        self.nonCpanelDbs = nonCpDbs
        return


    def getGrantsToFile(self, dbList):		#Identifies users associated with our databases. Gets grants for those users and only adds to the file if the database matches the specific database we're looking for
        userList = list()    

        for db in dbList:
            if "_" in db:
                tmpdb = db.split('_', 1)
                dbFixed = tmpdb[0] + "\\\_" + tmpdb[1]
            else:
                dbFixed = db
            data = self.mysqlCommand("SELECT user, host FROM mysql.db WHERE db='%s'" %dbFixed)
            for each in data.split():
                userList.append(each)
            if (len(userList)%2) != 0:
                print("PANIC The userList is not divisible by 2. We don't like this. This program is not happy. See userlist below:")
                print(userList)
                sys.exit()
            grantsOutFile = self.dbDumpPath + self.grantsFile
            with open(grantsOutFile, "a") as f:
                while len(userList) > 0:
                    user = userList.pop(0)
                    user = "'" + user + "'@'" + userList.pop(0) + "'"
                    f.write("# Grants for user: %s \n" %user)
                    data = self.mysqlCommand("SHOW GRANTS for %s" %user)
                    for dataSplit in data.split("\n"): 
                        if dataSplit == "":
                            f.write("\n\n")
                        elif (dbFixed in dataSplit) or ("IDENTIFIED BY" in dataSplit):
                            f.write(dataSplit + ";\n") 
        return 


    def dumpDbs(self, dbList):			#Uses the mysqldump command line tool to dump our happy databases to happy files in dbDumpPath
        try:
            os.makedirs(self.dbDumpPath)
        except OSError as exc:
            if exc.errno != 17:	#17 = EEXISI
                raise
        for db in dbList:
            p = subprocess.Popen(['mysqldump', '--routines', db], stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
            out, err = p.communicate()
            if not err=="":
                print("PANIC! IT'S AN ERROR: " + err)
                sys.exit()
            else:
                if self.verbose:
                    print("Dumping database: %s...." %db)
                with open(self.dbDumpPath + db + ".sql", "w") as file:
                    file.write(out)
        return



def listPrint(myList):			#Prints list items 1 per line
    for item in myList:
        print item
    return



def yesno(**kwargs):                    #stolen yesno function from dlau
    message=kwargs.get('message', '(y/n)')
    rv = -1
    while rv == -1:
        user=raw_input(message)
        if user.lower() in ['y', 'yes' ]:
            rv = 1
        elif user.lower() in [ 'n', 'no']:
            rv = 0
        else:
            print("try again");

    return rv

def usage():
    helpPage = """This program will dump databases created outside cPanel along with the grants associated with the databases for the users associated with the databases. Commandline arguments and their usages are below:

	Short:	Long:				Description:

	-h	--help				Print this message.

	-c	--check-only			Check for and display the databases that would be dump if the program was run fully.
						Use as last argument if you are overriding any default settings. Ignores silent, honors verbose.

	-f	--force				If dump path exists, move it out of the way and proceed.
						Default dump path = /home/temp/dbdumps/
						Default grants file name = grants.sql

	-i	--interactive			Interactive mode. Asks questions for paths, filenames, etc..

	-v					Verbose mode. Prints additional output.

	-s	--silent			Silent mode. Suppresses all output except for procedural questions which will still be asked 
						if --do-defaults is not also selected. Overrides verbose mode if both are selected for some reason.

		--yaml-path="<path>"		Override the default path to cpanel database .yaml files (/var/cpanel/databases/)

		--dbdump-path="<path>"		Override the default database dump path (/home/temp/dbdumps/)

		--grants-file="<filename>"	Override the default grants file name (grants.sql)

                --excludedb="<dbname>"		Excludes the named database from databses to dump. Adds to default list of cpanel/system databases to ignore.
						Can be used more than once.

		--skip-excludedb="<dbname>"	Remove a non-logaholic database from the default list of databases to exclude. Default list:
						        ["cphulkd", "eximstats", "horde", "information_schema", "leechprotect", "modsec",
						            "mysql", "performance_schema", "roundcube", "whmxfer"]


"""
    print(helpPage)
    return

def main():
    g = getDbs()
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hcsfiv", ["help", "check-only", "silent", "force", "interactive", "yaml-path=", "dbdump-path=", "excludedb=", "skip-excludedb="])
    except getopt.GetoptError as err:
        print(err)
        usage()
        sys.exit(2)
    for o, a in opts:
        if o == "-v":
            g.verbose = True
        elif o in ("-h", "--help"):
            usage()
            sys.exit()
	elif o in ("-c", "--check-only"):
            if g.interactive:
                g.askQuestions("all")
            g.doChecks()
            g.getCpDbs()
            g.getLocalDbs()
            g.getNonCpanelDbs(g.localDbs, g.cpanelDbs)
            print("Found:\n")
            listPrint(g.nonCpanelDbs)
            print("")
            sys.exit()
        elif o in ("-s", "--silent"):
            g.silent = True
        elif o in ("-f", "--force"):
            g.force = True
        elif o in ("-i", "--interactive"):
            g.interactive = True
        elif o == "--yaml-path":
            if not a.endswith("/"):
                a = a + "/"
            g.cpDbYamlPath = a
        elif o == "--dbdump-path":
            if not a.endswith("/"):
                a = a + "/"
            g.dbDumpPath = a
        elif o == "--grants-file":
            g.grantsFile = a
        elif o == "--excludedb":
            g.cpExcludeDbs.append(a)
        elif o == "--skip-excludedb":
            try:
                g.cpExcludeDbs.remove(a)
            except:
                print("HEY! %s isn't in the list. Ignoring you" %a)
        else:
            assert False, "unhandled option"
    if g.silent and g.verbose:
        g.verbose = False
    if g.interactive:
        g.askQuestions("all")
    g.doChecks()
    if not g.silent:
        print("\nFinding non-cPanel databases...\n")
    g.getCpDbs()
    g.getLocalDbs()
    g.getNonCpanelDbs(g.localDbs, g.cpanelDbs)
    if not g.silent:
        print("Found:\n")
        listPrint(g.nonCpanelDbs)
        print("\nDumping databases to %s$DBNAME.sql .... \n" %g.dbDumpPath)
    g.dumpDbs(g.nonCpanelDbs)
    if not g.silent:
        print("\nGetting grants associated with those databases and writing them to %s ... \n" %g.grantsFile)
    g.getGrantsToFile(g.nonCpanelDbs)
    if not g.silent:
        print("Done!\n")

if __name__ == "__main__":
    main()
