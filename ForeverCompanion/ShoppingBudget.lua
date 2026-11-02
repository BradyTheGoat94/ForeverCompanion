-- Conservative purchasing budget for outstanding manual recipe goals.
-- Does not query auction houses, vendors, bags, or execute purchases.
ForeverCompanionShoppingBudget={}
local B=ForeverCompanionShoppingBudget
function B.Build(prof)
 local plans=ForeverCompanionRecipePlans
 local costs=ForeverCompanionCraftCosts
 local forecast=plans and plans.MaterialForecast and plans.MaterialForecast(prof) or {}
 local rows,total,unknown={},0,0
 for _,item in ipairs(forecast) do
  local missing=math.max(0,tonumber(item.shortage) or 0)
  if missing>0 then
   local price=costs and costs.Get and costs.Get(prof,item.name) or nil
   local value=price and missing*price or nil
   if value then total=total+value else unknown=unknown+1 end
   rows[#rows+1]={name=item.name,missing=missing,price=price,copper=value}
  end
 end
 table.sort(rows,function(a,b)
  if (a.copper or -1)~=(b.copper or -1) then return (a.copper or -1)>(b.copper or -1) end
  return a.name<b.name
 end)
 return {rows=rows,knownCopper=total,unknown=unknown,complete=unknown==0}
end
function B.Format(prof)
 local report=B.Build(prof)
 local lines={"MATERIAL PURCHASE BUDGET - MANUAL COUNTS AND PRICES"}
 if #report.rows==0 then lines[#lines+1]="No material shortages in tracked recipe goals." end
 for _,row in ipairs(report.rows) do
  lines[#lines+1]=row.name.." x"..row.missing.." | "..(row.copper and (row.copper.." copper") or "PRICE NOT ENTERED")
 end
 lines[#lines+1]=(report.complete and "Estimated total: " or "Known subtotal (incomplete): ")..report.knownCopper.." copper"
 if report.unknown>0 then lines[#lines+1]=report.unknown.." materials have no entered price." end
 lines[#lines+1]="Planning only; no live auction data or automatic buying."
 return table.concat(lines,"\n")
end
