dofile('ForeverCompanion/ServiceClusters.lua')
local build=ForeverCompanionServiceClusters.Build
local points={
 {x=.1,y=.1,symbol='B',label='Bank',service='Bank'},
 {x=.11,y=.1,symbol='R',label='Smith',service='Repair'},
 {x=.8,y=.8,symbol='I',label='Inn',service='Inn'},
 {x=0/0,y=.5,symbol='V',label='invalid'},
}
local groups=build(points,1000,600,22)
assert(#groups==2 and #groups[1]==2)
assert(groups[1][1]==points[1])
assert(#build(points,3000,1800,22)==3,'zoom separates distinct coordinates')
local reversed={points[3],points[2],points[1]}
local other=build(reversed,1000,600,22)
assert(other[1][1]==groups[1][1],'provider iteration order cannot move cluster representative')
assert(#build({},1000,600,22)==0,'map switches start with empty clusters')
print('PASS: mixed-service clusters, zoom separation, stable representatives, invalid coordinates')
