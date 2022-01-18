* Calculate the reserved guid-s by the formula 43000 + ($uid - $a4e_user_uid) * 5
* The following assumptions and constraints take place here:
* Constraint: max UID and GUID is 256000, this is a system limitation.
* Constraint: UID/GUID range 1002 - 1100 are system reserved. GUID 1002 is the a4e_internal group, UID/GUID 1100 is for clearlypro
* Constraint: UID/GUID range 1010 - 1060 are clearance level groups that give access to specific keys. For more details check permission_groups.sh in this directory.
* Constraint: employee accounts have UID/GUID range 1101 - 5100
* Constraint: client   accounts have UID/GUID range 5100 - 42999 (god bless my optimism)
* Assumption: At its peak, A4E Corp. will have 37,899 clients and 3999 employees. We leave 5 reserved gids for each main gid.
* Assumption: ${A4E_USER} has the lowest UID of all the ftp users and it is 1001.
* Given these, the last 5 reserved GUIDs would be 252,990 : 252,994, which is just below the OS limit of 256,000
* Reserved GUID 1/5 is for ${user}_internal group, where only a4e employees can be members.
