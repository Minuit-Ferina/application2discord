string token	  = "Bot xxx";
string channel_id = "";

string api		  = "https://discord.com/api/v10";
string agent	  = "User-Agent: DiscordBot ("
					", 1)";

list notecard_name_processed;
string current_notecard;
key current_key;
integer current_line_number;
string current_body;

createThread(string name, string line, string notecart)
{
	string json;
	json = llJsonSetValue(json, ["name"], name);
	json = llJsonSetValue(json, ["type"], "11");
	json = llJsonSetValue(json, ["message", "content"], line);

	string body;
	body += "--------------------------boundaryString\n";
	body += "Content-Disposition: form-data; name=\"payload_json\"\n";
	body += "Content-Type: application/json\n";
	body += "\n";
	body += json + "\n";
	body += "--------------------------boundaryString\n";

	body += "Content-Disposition: form-data; name=\"file\"; filename=\"example.txt\"\n";
	body += "Content-Type: text/plain\n";
	body += "\n";
	body += notecart + "\n";
	body += "--------------------------boundaryString--\n";

	// llOwnerSay(body);

	llHTTPRequest(api + "/channels/" + channel_id + "/threads", [
		HTTP_METHOD, "POST",
		HTTP_MIMETYPE, "multipart/form-data; boundary=------------------------boundaryString",
		// HTTP_USER_AGENT, agent,
		HTTP_CUSTOM_HEADER, "Authorization",
		token
	],
				  body);
}

postMessage(string msg)
{
	llHTTPRequest(api + "/channels/" + channel_id + "/messages", [
		HTTP_METHOD, "POST",
		HTTP_MIMETYPE, "application/json",
		// HTTP_USER_AGENT, agent,
		HTTP_CUSTOM_HEADER, "Authorization",
		token
	],
				  "{\"content\": " + msg + "}");
}

process_notecard()
{
	integer vIntLMcount = llGetInventoryNumber(INVENTORY_NOTECARD);
	if(vIntLMcount > 0)
	{
		integer c = 0;
		// llOwnerSay(llList2CSV(notecard_name_processed));
		for(; c < vIntLMcount; c++)
		{
			string notecard = llGetInventoryName(INVENTORY_NOTECARD, c);
			// llOwnerSay("test2");
			// llOwnerSay("c " + (string)c);
			// llOwnerSay("notecard " + (string)notecard);
			if(llListFindList(notecard_name_processed, [notecard]) < 0)
			{
				// llOwnerSay("test3");

				current_body		= "";
				current_line_number = 0;
				current_notecard	= notecard;
				// llOwnerSay("process_notecard: " + current_notecard);
				current_key			= llGetNotecardLine(current_notecard, 0);
				return;
			}
		}
		llSetTimerEvent(0);
	}
}

list remove_from_list(list l, list e)
{
	integer index = llListFindList(l, e);
	l			  = llDeleteSubList(l, index, index);
	return l;
}

default
{
	state_entry() { }

	touch_start(integer total_number) { }

	http_response(key request_id, integer status, list metadata, string body)
	{
		// llOwnerSay("request_id: " + (string)request_id);
		// llOwnerSay("status: " + (string)status);
		// llOwnerSay("metadata: " + (string)metadata);
		// llOwnerSay("body: " + (string)body);
	}

	changed(integer change)
	{
		if(change == CHANGED_INVENTORY)
		{
			integer vIntLMcount = llGetInventoryNumber(INVENTORY_NOTECARD);
			if(vIntLMcount == 0)
			{
				notecard_name_processed = [];
			}
			else if(vIntLMcount)
			{
				{
					integer c = 0;
					integer n = llGetListLength(notecard_name_processed);
					for(; c < n; c++)
					{
						string k = llList2String(notecard_name_processed, c);
						if(llGetInventoryType(k) == INVENTORY_NONE)
						{
							notecard_name_processed = remove_from_list(notecard_name_processed, [k]);
						}
					}
				}
				process_notecard();
			}
		}
	}

	timer()
	{
		process_notecard();
	}

	dataserver(key queryid, string data)
	{
		if(queryid == current_key)
		{
			if(data != EOF)
			{
				current_body += data + "\n";
				current_line_number++;
				current_key = llGetNotecardLine(current_notecard, current_line_number);
			}
			else
			{
				key uuid	   = llGetInventoryKey(current_notecard);
				string creator = llGetInventoryCreator(current_notecard);
				string date	   = llGetInventoryAcquireTime(current_notecard);
				createThread(llGetDisplayName(creator), "Received on " + date, current_body);
				notecard_name_processed += current_notecard;
				llSetTimerEvent(10);
			}
		}
	}
}
