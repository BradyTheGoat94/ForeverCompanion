dofile('ForeverCompanion/ResearchNotebook.lua')
local n=ForeverCompanionResearchNotebook
local db={}
assert(not n.Save(nil,'Legacy',{}))
assert(not n.Save(db,'Unknown',{}))
assert(n.Read(db,'Legacy').note=='')
assert(db.researchNotes==nil,'reads must not mutate storage')
assert(n.Save(db,'Legacy',{note='Test |Hitem:1|h\nnew',source='https://example.test/source',build='test build'}))
local saved=n.Read(db,'Legacy')
assert(not saved.note:find('|',1,true) and not saved.note:find('\n',1,true),'strip UI escapes and control text')
assert(saved.source=='https://example.test/source')
assert(n.Read(db,'Alts').note=='','page isolation')
assert(n.Save(db,'Boss:Dungeon:Boss',{note=string.rep('x',400),source=string.rep('s',300),build=string.rep('b',100)}))
local boss=n.Read(db,'Boss:Dungeon:Boss')
assert(#boss.note==320 and #boss.source==240 and #boss.build==80)
assert(n.Save(db,'Legacy',{}))
assert(db.researchNotes.Legacy==nil,'empty notes should clear storage')
assert(n.Read(db,'Boss:Dungeon:Boss').note~='','clear must not affect another context')
db.researchNotes='corrupt'
assert(n.Save(db,'Alts',{note='Recovered'}))
assert(n.Read(db,'Alts').note=='Recovered')
ForeverCompanionEncounterBrowser={dungeon='A',boss='B'}
assert(n.Context('Dungeons')=='Boss:A:B')
ForeverCompanionEncounterBrowser.boss='C'
assert(n.Context('Dungeons')=='Boss:A:C')
assert(n.Context('Leveling')==nil)
print('PASS: research note bounds, recovery, sanitization, clearing and context isolation')


assert(n.Save(db,'Legacy',{note=string.rep('a',319)..'é',source=string.rep('s',238)..'猫',build=string.rep('b',79)..'🙂'}))
local localized=n.Read(db,'Legacy')
assert(localized.note==string.rep('a',319))
assert(localized.source==string.rep('s',238))
assert(localized.build==string.rep('b',79))
assert(n.Save(db,'Alts',{note=string.rep('a',318)..'é'}))
assert(n.Read(db,'Alts').note==string.rep('a',318)..'é','complete character at boundary retained')
print('PASS: UTF-8 notebook boundaries')
