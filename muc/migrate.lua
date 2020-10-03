
-- setup paths to use Prosody libraries
package.path = package.path .. ';/usr/lib/prosody/?.lua';
package.cpath = package.cpath .. ';/usr/lib/prosody/?.so';

local lfs = require "lfs";
local xml_parse = require "util.xml".parse;
local datamanager = require "util.datamanager";

local MUC_HOST = "conference.jabber.org";

function load_xml(path)
	local f = assert(io.open(path));
	local s = assert(f:read("*a"));
	assert(f:close());

	return xml_parse(s);
end

local text_elements = {
	"Name";
	"PubsubAccessModel";
	"PubsubPublishModel";
	"PubsubItemChangeCallback";
	"Xep45DefaultRole";
	"Description";
	"Xep45Subject";
	"Xep45Password";
	"Xep45RealjidsRole";
	"Xep45SubjectRole";
	"Xep45PrivMsgRole";
	"Xep45InviteRole";
	"Xep45SubjectWho";
};
local numeric_elements = {
	"PubsubMaxItems";
	"FmucHistoryLen";
	"Xep45DefaultHistory";
	"Xep45DefaultHistoryLen";
	"Xep45MaxOccupants";
	"Xep45SubjectWhen";
};
local array_elements = {
	"PubsubOutcast";
	"PubsubMember";
	"PubsubAdministrator";
	"PubsubOwner";
};
local boolean_elements = {
	"PubsubPublic";
	"Xep45vCards";
	"Xep45Html";
	"Xep45PassAny";
};

local elements = {};

local affiliation_map = {
	PubsubOutcast = "outcast";
	PubsubMember = "member";
	PubsubAdministrator = "admin";
	PubsubOwner = "owner";
}

local jid = require "util.jid";

function load_muc_config(room_jid, path)
	assert(room_jid == jid.prep(room_jid));
	local stanza = load_xml(path);
	assert(stanza.name == 'Chatroom', 'execting top element to be <Chatroom>');

	local room = { _data = {} };
	room.jid = room_jid;
	room._data.persistent = true;
	room._data.hidden = true;

	local affiliations = {};
	for _, tag in ipairs(stanza.tags) do
		assert(#tag == 1 and type(tag[1]) == "string");
		local name = tag.name;
		local text = tag[1];

		if name == "Name" then
			assert(not room._data.name);
			room._data.name = text;
		elseif name == "PubsubPublic" then
			assert(room._data.hidden == true and text == "true");
			room._data.hidden = false;
		elseif name == "PubsubAccessModel" then
			assert(text == "open");
		elseif name == "PubsubPublishModel" then
			assert(text == "publishers");
			-- TODO
		elseif name == "PubsubMaxItems" then
			assert(not room._data.history_length);
			assert(not room._data.default_history_messages);

			room._data.history_length = assert(tonumber(text));
			room._data.default_history_messages = room._data.history_length;
		elseif name == "PubsubItemChangeCallback" then
			assert(text == "xep45");
		elseif name == "Xep45DefaultRole" then
			-- TODO review
			assert(room._data.moderated == nil and room._data.members_only == nil);
			if text == "none" then
				room._data.members_only = true;
			elseif text == "visitor" then
				room._data.moderated = true;
			else
				assert(false);
			end
		elseif name == "Description" then
			assert(not room._data.description);
			room._data.description = text;
		elseif name == "Xep45Subject" then
			assert(not room._data.subject);
			room._data.subject = text;
		elseif name == "Xep45Password" then
			assert(not room._data.password);
			room._data.password = text;
		elseif name == "Xep45RealjidsRole" then
			-- TODO review
			assert(not room._data.whois);
			if text == "none" then
				room._data.whois = "moderators";
			elseif text == "moderator" then
				room._data.whois = "moderators";
			elseif text == "participant" then
				room._data.whois = "anyone";
			elseif text == "visitor" then
				room._data.whois = "anyone";
			else
				assert(false);
			end
		elseif name == "Xep45vCards" then
		elseif name == "Xep45Html" then
		elseif name == "Xep45PassAny" then
			-- ?
		elseif name == "Xep45SubjectRole" then
			-- TODO review
			assert(room._data.changesubject == nil);
			if text == "none" then
				room._data.changesubject = nil;
			elseif text == "participant" then
				room._data.changesubject = true;
			else
				assert(false);
			end
		elseif name == "Xep45PrivMsgRole" then
			-- Not implemented in Prosody
		elseif name == "Xep45InviteRole" then
			-- TODO review
			-- Note: In Prosody this only applies for members-only rooms
			assert(room._data.allow_member_invites == nil);
			if text == "none" then
				room._data.allow_member_invites = false;
			elseif text == "moderator" then
				room._data.allow_member_invites = false;
			elseif text == "participant" then
				room._data.allow_member_invites = true;
			else
				assert(false);
			end
		elseif name == "FmucHistoryLen" then
		elseif name == "Xep45SubjectWho" then
			assert(not room._data.subject_from);
			room._data.subject_from = assert(jid.prep(text));
		elseif name == "Xep45SubjectWhen" then
			assert(not room._data.subject_time);
			room._data.subject_time = assert(tonumber(text));
		elseif name == "Xep45DefaultHistory" then
			-- TODO
		elseif name == "" then
		elseif name == "" then
		elseif name == "" then
		elseif name == "" then
		elseif name == "" then
		elseif name == "" then
		elseif name == "" then
		elseif affiliation_map[name] then
			local prepped = jid.prep(text);
			assert(prepped, "invalid jid: "..text);
			assert(prepped == text, "unprepped jid: "..text.." vs "..prepped);
			assert(not affiliations[prepped], "jid already affiliated: "..text);
			affiliations[prepped] = affiliation_map[name];
		else
		end
	end
	room._affiliations = affiliations;
	return room;
end

local json = require "util.json";


local urldecode = require "util.http".urldecode;

local base = "cjo_configs";
local index = {};

datamanager.set_data_path("output");
for filename in lfs.dir(base) do
	local nodename = filename:match("^(.+)%.xml$");
	if nodename then
		nodename = urldecode(nodename);
		local room_jid = nodename .. "@" .. MUC_HOST;
		local data = load_muc_config(room_jid, base .. "/" .. filename);
		datamanager.store(nodename, MUC_HOST, "config", data);
		index[room_jid] = true;
	end
end
datamanager.store(nil, MUC_HOST, "persistent", index);
