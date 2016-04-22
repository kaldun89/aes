/* 
	Advanced Experience System
	by serfreeman1337		http://gf.hldm.org/
*/

/*
	Experience Editor
*/

#include <amxmodx>
#include <amxmisc>

#include <aes_main>

#define PLUGIN "AES: Experience Editor"
#define VERSION "0.1"
#define AUTHOR "serfreeman1337"

#define USE_COLORCHAT

#if defined USE_COLORCHAT
	#include <colorchat>
#endif

enum _:cvars {
	CVAR_EXP_MENU
}

new cvar[cvars]

new Array:g_ExpsVals

enum _:menuStatus {
	MENU_EDITID,
	MENU_SETMODE,
	MENU_CURRENT
}

enum _:menuCurrent {
	MID_LIST,
	MID_ACT,
	MID_ADD_EXP,
	MID_SET_LEVEL,
	MID_SET_BONUSES
}

enum _:menuSetMode {
	M_ADD_EXP = 1,
	M_SUB_EXP,
	M_SET_EXP,
	M_SET_BONUSES,
	M_SET_LEVEL
}

new g_MenuStatus[33][menuStatus]

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("aes_exp_menu","C_Show_Exp_Menu",ADMIN_CVAR,"- open AES experience menu")
	register_concmd("aes_exp_menu_set","C_Set_Exp",ADMIN_CVAR,"<name or #userid> <experience>")
	register_concmd("aes_exp_menu_level","C_Set_Level",ADMIN_CVAR,"<name or #userid> <level>")
	
	cvar[CVAR_EXP_MENU] = register_cvar("aes_exp_menu_value","1 5 10 15 20 50 100")
	
	register_clcmd("caes_exp_menu_set","C_Exp_Set")
	
	register_dictionary("aes_expeditor.txt")
	
}

public C_Show_Exp_Menu(id,level,cid){
	if(!cmd_access(id,level,cid,0))
		return PLUGIN_HANDLED
	
	E_Build_Players_Menu(id)
		
	return PLUGIN_HANDLED
}

public C_Set_Exp(id,level,cid){
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED

	new args[128]
	read_args(args,127)
	
	trim(args)
	remove_quotes(args)
	
	new usrId[32],sExpVal[32],expVal
	strtok(args,usrId,31,sExpVal,31,' ',1)
	
	new player = cmd_target(id,usrId,CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF)
	
	if(!player)
		return PLUGIN_HANDLED
		
	expVal = max(0,str_to_num(sExpVal))
		
	new stats[3]
	
	stats[0] = expVal
	stats[1] = -1
	stats[2] = -1
	
	if(aes_set_player_stats(player,stats)){
		new vicName[32]
		get_user_name(player,vicName,31)
		
		client_print(id,print_console,"%L %L",
			id,"AES_TAG_CON",
			id,"ACT_CON_EXP",
			vicName,expVal)
			
		A_Chat_Msg(id,player,M_SET_EXP,expVal)
	}else{
		client_print(id,print_console,"%L %L",
			id,"AE_TAG_CON",
			id,"ACT_WRONG")
	}
		
	return PLUGIN_HANDLED
}

public C_Set_Level(id,level,cid){
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
		
	new args[128]
	read_args(args,127)
	
	trim(args)
	remove_quotes(args)
	
	new usrId[32],expVal,sExpVal[32]
	strtok(args,usrId,31,sExpVal,31,' ',1)
	
	new player = cmd_target(id,usrId,CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF)
	
	if(!player)
		return PLUGIN_HANDLED
		
	expVal = max(0,str_to_num(sExpVal))
		
	new stats[3]
	
	stats[0] = -1
	stats[1] = expVal
	stats[2] = -1
	
	if(aes_set_player_stats(player,stats)){
		new vicName[32],vicLevel[32]
		get_user_name(player,vicName,31)
		aes_get_level_name(stats[1],vicLevel,31,id)
		
		client_print(id,print_console,"%L %L",
			id,"AES_TAG_CON",
			id,"ACT_CON_LEVEL",
			vicName,vicLevel)
			
		A_Chat_Msg(id,player,M_SET_LEVEL,expVal)
	}else{
		client_print(id,print_console,"%L %L",
			id,"AE_TAG_CON",
			id,"ACT_WRONG")
	}
	
	return PLUGIN_HANDLED
}

// ��������� ������ �������� ����� ��� �������
public C_Exp_Set(id,level,cid){
	// ��������� �������
	if(!cmd_access(id,level,cid,0))
		return PLUGIN_HANDLED
		
	// ��������� ��� �������� ���� ������� ����� ����
	if(!g_MenuStatus[id][MENU_SETMODE])
		return PLUGIN_HANDLED
		
	// ����� ����������. ������ �� ������.
	if(!is_user_connected(g_MenuStatus[id][MENU_EDITID]))
		return PLUGIN_HANDLED
		
	new sExpVal[20],expVal
	
	read_args(sExpVal,19)
	trim(sExpVal)
	remove_quotes(sExpVal)
	
	// ����� �� ���� �������� ������ �� ������.
	if(!strlen(sExpVal))
		return PLUGIN_HANDLED
	
	expVal = str_to_num(sExpVal)
	
	switch(g_MenuStatus[id][MENU_SETMODE]){
		case M_ADD_EXP,M_SUB_EXP,M_SET_EXP:{
			if(g_MenuStatus[id][MENU_SETMODE] != M_SET_EXP){
				aes_add_player_exp(g_MenuStatus[id][MENU_EDITID],
					g_MenuStatus[id][MENU_SETMODE] == M_ADD_EXP ? expVal : -expVal,1)
				
				A_Chat_Msg(id,g_MenuStatus[id][MENU_EDITID],g_MenuStatus[id][MENU_SETMODE] == M_SUB_EXP ? M_SUB_EXP : M_ADD_EXP,
					g_MenuStatus[id][MENU_SETMODE] == M_SUB_EXP ? -expVal : expVal)
			}else{
				new stats[3] = -1
				
				stats[AES_ST_EXP] = expVal
				stats[AES_ST_LEVEL] = -1
				stats[AES_ST_BONUSES] = -1
				
				aes_set_player_stats(g_MenuStatus[id][MENU_EDITID],stats)
			}
		}
		case M_SET_BONUSES:{
			new stats[3] = -1
				
			stats[AES_ST_EXP] = -1
			stats[AES_ST_LEVEL] = -1
			stats[AES_ST_BONUSES] = expVal
			
			A_Chat_Msg(id,g_MenuStatus[id][MENU_EDITID],M_SET_BONUSES,expVal)
			aes_set_player_stats(g_MenuStatus[id][MENU_EDITID],stats)
		}
	}
	
	// ���������� ���� �������� ��� �������
	E_Build_Action_Menu(id,g_MenuStatus[id][MENU_EDITID])
	
	return PLUGIN_HANDLED
}


public A_Chat_Msg(id,editId,actId,valuev){
	new admName[32],admAuth[36],editName[32],editAuth[36]
	
	get_user_name(id,admName,31)
	get_user_name(editId,editName,31)

	get_user_authid(id,admAuth,35)
	get_user_authid(editId,editAuth,35)
	
	new const LangAct[][] = {
		"",
		"ACT_ADD_EXP",
		"ACT_SUB_EXP",
		"ACT_ADD_EXP",
		"ACT_SET_BONUS",
		"ACT_SET_LEVEL"
	}
	
	new const LogAct[][] = {
		"",
		"add <s> exp",
		"sub <s> exp",
		"set <s> exp",
		"set <s> bonuses",
		"set level <s> for"
	}
	
	new nikolay[32]
		
	if(actId == M_SET_LEVEL){
		aes_get_level_name(valuev,nikolay,31,editId)
	}else{
		formatex(nikolay,31,"%d",actId != M_SUB_EXP ? valuev : -valuev)
	}
	
	new logMsg[46]
	formatex(logMsg,45,"%s",LogAct[actId])
	replace_all(logMsg,45,"<s>",nikolay)
	
	log_amx("^"%s<%d><%s><>^" %s ^"%s<%d><%s><>^"",
		admName,
		get_user_userid(id),
		admAuth,
		
		logMsg,
		
		editName,
		get_user_userid(editId),
		editAuth)
	
	#if defined USE_COLORCHAT
		client_print_color(editId,0,"%L %L",
			editId,"AES_TAG",
			editId,LangAct[actId],
			admName,
			nikolay)
			
		if(id != editId)
			client_print_color(id,0,"%L %L",
				editId,"AES_TAG",
				id,LangAct[actId],
				nikolay,
				editName)
	#else
		client_print(editId,print_chat,"%L %L",
			id,"AES_TAG",
			editId,LangAct[actId],
			admName,
			nikolay)
			
		if(id != editId)
			client_print(id,print_chat,"%L %L",id,LangAct[actId],
				id,"AES_TAG",
				nikolay,
				editName)
	#endif
}

// ������ �������
public E_Build_Players_Menu(id){
	arrayset(g_MenuStatus[id],0,menuStatus)
	
	new langStr[96]
	formatex(langStr,95,"%L %L",id,"AES_TAG_MENU",id,"TITLE")
	
	new m = menu_create(langStr,"E_Menu_Handler")
	
	g_MenuStatus[id][MENU_CURRENT] = MID_LIST
	
	new players[32],pCount
	new aStats[AES_ST_END],name[32],lKey[10]
	
	get_players(players,pCount)
	
	for(new i ; i < pCount ; ++i){
		get_user_name(players[i],name,31)
		aes_get_player_stats(players[i],aStats)
		
		formatex(langStr,95,"%s \y(%d/%d)",name,aStats[AES_ST_EXP],aes_get_exp_to_next_level(aStats[AES_ST_LEVEL]))
		formatex(lKey,9,"l%d",players[i])
		
		menu_additem(m,langStr,lKey)
	}
	
	F_Format_NavButtons(id,m)
	menu_display(id,m)
}

// ���� ��������
public E_Build_Action_Menu(id,editId){
	if(!is_user_connected(editId)){
		E_Build_Players_Menu(id)
				
		return PLUGIN_CONTINUE
	}
	
	g_MenuStatus[id][MENU_CURRENT] = MID_ACT
	
	new langStr[96],actName[32],lKey[10]
	get_user_name(editId,actName,31)
	
	formatex(langStr,95,"%L %L %s",id,"AES_TAG_MENU",id,"TITLE_ACT",actName)
	
	new m = menu_create(langStr,"E_Menu_Handler")
	
	formatex(langStr,95,"%L",id,"ADD_EXP")
	formatex(lKey,9,"e1#%d",editId)
	menu_additem(m,langStr,lKey)
	
	formatex(langStr,95,"%L",id,"SUB_EXP")
	formatex(lKey,9,"e2#%d",editId)
	menu_additem(m,langStr,lKey)
	
	formatex(langStr,95,"%L",id,"SET_EXP")
	formatex(lKey,9,"e3#%d",editId)
	menu_additem(m,langStr,lKey)
	
	formatex(langStr,95,"%L",id,"SET_LEVEL")
	formatex(lKey,9,"e4#%d",editId)
	menu_additem(m,langStr,lKey)
	
	formatex(langStr,95,"%L",id,"SET_BONUSES")
	formatex(lKey,9,"e5#%d",editId)
	menu_additem(m,langStr,lKey)
	
	E_Menu_Add_Player_Info(id,editId,m)
	
	menu_display(id,m)
	
	return PLUGIN_CONTINUE
}


// ���������� � ������� ������ � ����
public E_Menu_Add_Player_Info(id,editId,m){
	new langStr[128],actName[32]
	get_user_name(editId,actName,31)
	
	new aStats[AES_ST_END],aLevel[32]
	
	aes_get_player_stats(editId,aStats)
	aes_get_level_name(aStats[AES_ST_LEVEL],aLevel,31,id)
	
	formatex(langStr,127,"%L",id,"EXP_TEXT",
		actName,
		aStats[AES_ST_EXP],aes_get_exp_to_next_level(aStats[AES_ST_LEVEL]),
		aStats[AES_ST_LEVEL] + 1,aLevel,
		aStats[AES_ST_BONUSES])
	menu_addtext(m,langStr)
}

// ���� ���������� ��� ��������� �����
public E_Build_Exp_Menu(id,editId,bool:isSub){
	// ���������� ������ �������, ���� ��������� ����� ����������
	if(!is_user_connected(editId)){
		E_Build_Players_Menu(id)
				
		return PLUGIN_CONTINUE
	}
	
	g_MenuStatus[id][MENU_CURRENT] = MID_ADD_EXP
	g_MenuStatus[id][MENU_EDITID] = editId
	
	// ��������� ������ �� ��������� �����
	if(g_ExpsVals == Invalid_Array)
		V_Load_Exp_Vals()
		
	new langStr[96],cell,lKey[10]
	
	formatex(langStr,95,"%L %L",id,"AES_TAG_MENU",id,!isSub ? "ADD_EXP" : "SUB_EXP")
	
	new m = menu_create(langStr,"E_Menu_Handler")
	
	for(new i ; i < ArraySize(g_ExpsVals) ; ++i){
		cell = ArrayGetCell(g_ExpsVals,i)
		
		formatex(langStr,95,"%L",id,!isSub ? "ADD_EXP_ITEM" : "SUB_EXP_ITEM",cell)
		formatex(lKey,9,"d%d#%s%d",editId,!isSub ? "" : "-" , cell)
		
		menu_additem(m,langStr,lKey)
	}
	
	formatex(langStr,95,"%L",id,"EXP_SELF")
	formatex(lKey,9,"d%d#%sself",editId, !isSub ? "" : "-")
	
	menu_additem(m,langStr,lKey)
	
	// E_Menu_Add_Player_Info(id,editId,m)
	
	F_Format_NavButtons(id,m)
	menu_display(id,m)
		
	return PLUGIN_CONTINUE
}

public F_Format_NavButtons(id,menu){
	new tmpLang[20]
	
	formatex(tmpLang,19,"%L",id,"BACK")
	menu_setprop(menu,MPROP_BACKNAME,tmpLang)
	
	formatex(tmpLang,19,"%L",id,"EXIT")
	menu_setprop(menu,MPROP_EXITNAME,tmpLang)
	
	formatex(tmpLang,19,"%L",id,"MORE")
	menu_setprop(menu,MPROP_NEXTNAME,tmpLang)
}

// ���� ��� ������� ������ ������
public E_Build_Level_Menu(id,editId){
	// ���������� ������ �������, ���� ��������� ����� ����������
	if(!is_user_connected(editId)){
		E_Build_Players_Menu(id)
				
		return PLUGIN_CONTINUE
	}
	
	g_MenuStatus[id][MENU_CURRENT] = MID_SET_LEVEL
	g_MenuStatus[id][MENU_EDITID] = editId
	
	new langStr[96],lKey[10]
	
	formatex(langStr,95,"%L %L",id,"AES_TAG_MENU",id,"SET_LEVEL")
	
	new m = menu_create(langStr,"E_Menu_Handler")
	
	new eStats[AES_ST_END],pageCnt = -1,pageLevel
	aes_get_player_stats(editId,eStats)
	
	for(new i ; i < aes_get_max_level() ; ++i){
		// ������� ����� ���-�� �������
		if(!(i % 7))
			pageCnt ++
		
		langStr[0] = 0
		aes_get_level_name(i,langStr,95,id)
		
		new lvl = i - 1
		
		if(eStats[AES_ST_LEVEL] != i){
			formatex(langStr,95,"%s \r[\y%d\r]",langStr,lvl > -1 ? aes_get_exp_to_next_level(lvl) : 0)
		}else{
			// ���������� �������� ������ ������
			
			pageLevel = pageCnt
			formatex(langStr,95,"%s \r[\y%d\r] %L",
				langStr,lvl > -1 ? aes_get_exp_to_next_level(lvl) : 0,
				id,"CUR_LEVEL")
		}
		
		formatex(lKey,9,"s%d#%d",editId,i)
		
		menu_additem(m,langStr,lKey)
	}
	
	F_Format_NavButtons(id,m)
	menu_display(id,m,pageLevel)
	
	return PLUGIN_CONTINUE
}

public V_Load_Exp_Vals(){
	new expString[512],stPos,ePos,rawPoint[20]
	get_pcvar_string(cvar[CVAR_EXP_MENU],expString,511)
	
	g_ExpsVals = ArrayCreate(1)
	
	if(strlen(expString)){
		do {
			ePos = strfind(expString[stPos]," ")
			
			formatex(rawPoint,ePos,expString[stPos])
			ArrayPushCell(g_ExpsVals,str_to_num(rawPoint))
			
			stPos += ePos + 1
		} while (ePos != -1)
	}
}

public E_Menu_Handler(id,m,item){
	if(item == MENU_EXIT){
		menu_destroy(m)
		
		// ��������� ��������� ����
		switch(g_MenuStatus[id][MENU_CURRENT]){
			case MID_ACT: E_Build_Players_Menu(id)
			case MID_ADD_EXP,MID_SET_LEVEL,MID_SET_BONUSES: E_Build_Action_Menu(id,g_MenuStatus[id][MENU_EDITID])
		}
		
		return PLUGIN_HANDLED
	}
	
	new itemData[20]
	new a,n[2]
	
	menu_item_getinfo(m,item,a,itemData,19,n,1,a)
	
	switch(itemData[0]){
		case 'l':{ // ���������� ���� �������� ��� �������� �������
			E_Build_Action_Menu(id,str_to_num(itemData[1]))
		}
		case 'e':{ // ��������� �������� ��������
			new SeKey[2],SeEditId[3]
			
			// ��������� ���������� ������ ����
			strtok(itemData[1],SeKey,1,SeEditId,2,'#')
			
			new eKey = str_to_num(SeKey) // ������ ID ��������
			new editId = str_to_num(SeEditId) // ������ ID ������
			
			switch(eKey){
				// ���� ��������/������ ����
				case 1,2: E_Build_Exp_Menu(id,editId,eKey == 1 ? false : true)
				case 3:{ // ��������� ���� �������
					g_MenuStatus[id][MENU_SETMODE] = M_SET_EXP
					g_MenuStatus[id][MENU_EDITID] = editId
					
					client_cmd(id,"messagemode caes_exp_menu_set")
				}
				// ������ ������� ������
				case 4: E_Build_Level_Menu(id,editId)
				// ������ ������ ������
				case 5:{
					g_MenuStatus[id][MENU_SETMODE] = M_SET_BONUSES
					g_MenuStatus[id][MENU_EDITID] = editId
					
					client_cmd(id,"messagemode caes_exp_menu_set")
				}
			}
			
		}
		case 'd':{ // ��������� ��� �������� ����
			new SeEditId[3],SeVal[20]
			
			strtok(itemData[1],SeEditId,2,SeVal,19,'#')
			
			new editId = str_to_num(SeEditId)
			
			// ������ ���� �������
			if(contain(SeVal,"self") != -1){
				g_MenuStatus[id][MENU_SETMODE] = SeVal[0] != '-' ? M_ADD_EXP : M_SUB_EXP
				g_MenuStatus[id][MENU_EDITID] = editId
				
				client_cmd(id,"messagemode caes_exp_menu_set")
				
				return PLUGIN_HANDLED
			}
			
			new val = str_to_num(SeVal)
			
			aes_add_player_exp(editId,val,1)
			
			// ���������� ���� �������� �����
			E_Build_Action_Menu(id,editId)
			A_Chat_Msg(id,editId,SeVal[0] != '-' ? M_ADD_EXP : M_SUB_EXP,val)
		}
		case 's':{ // ��������� ������
			new SeEditId[3],SeVal[20]
			
			strtok(itemData[1],SeEditId,2,SeVal,19,'#')
			
			new editId = str_to_num(SeEditId)
			new stats[3] = -1
			
			stats[AES_ST_EXP] = -1
			stats[AES_ST_LEVEL] = str_to_num(SeVal)
			stats[AES_ST_BONUSES] = -1
			
			aes_set_player_stats(editId,stats)
			
			E_Build_Level_Menu(id,editId)
			A_Chat_Msg(id,editId,M_SET_LEVEL,stats[AES_ST_LEVEL])
		}
	}
	
	return PLUGIN_HANDLED
}

// � ����� ������ ����������� ._.
