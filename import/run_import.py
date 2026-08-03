# -*- coding: utf-8 -*-
"""
Import ข้อมูลจริงจาก Google Sheets -> Supabase (ครั้งเดียวจบ)

รันด้วยบัญชี Admin ผ่าน PostgREST (policy admin_write = ต้องมีสิทธิ์ roles.manage)
ข้อมูลไม่ผ่านแชท — อ่านไฟล์ CSV ในโฟลเดอร์นี้แล้วยิงเข้า API โดยตรง

การแก้ข้อมูลที่ทำระหว่าง import (ตกลงกับ Ben 2026-08-03):
  • buyer_focus  : หัวคอลัมน์กับข้อมูลเหลื่อมกัน 1 ช่อง (คอลัมน์ 2-7) -> จับคู่ใหม่ตามความหมายจริง
  • listings     : ทิศ/ตำแหน่ง/อายุ/ส่วนกลาง กรอกผิดช่องเกือบทั้งชีท -> เอาเฉพาะค่าที่อยู่ถูกช่องจริง
  • โครงการ      : จับคู่ด้วย "ชื่อไทย" (ชื่ออังกฤษในชีททรัพย์เป็นภาษาไทย จับคู่ได้ 1/508)
  • Listing ID ซ้ำ : ขยับเป็นเลขว่างถัดไป
  • hook         : เอามาจากคอลัมน์ Buyer Persona
  • ชื่อเล่น -> employee_code, "Stone Bangyai" -> Stone
"""
import csv, io, json, os, re, sys, urllib.request, urllib.error
from collections import Counter, defaultdict

BASE = "https://jpufhxzvqfrdcblfmrmu.supabase.co"
ANON = "sb_publishable_MXdGWde2_RvLAWQrJ0ORWw_K18B0rvc"
HERE = os.path.dirname(os.path.abspath(__file__))
sys.stdout.reconfigure(encoding="utf-8")

# ---------- HTTP ----------
def req(method, path, body=None, token=None, prefer=None):
    url = BASE + path
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("apikey", ANON)
    r.add_header("Content-Type", "application/json")
    if token: r.add_header("Authorization", "Bearer " + token)
    if prefer: r.add_header("Prefer", prefer)
    try:
        with urllib.request.urlopen(r) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw.strip() else None
    except urllib.error.HTTPError as e:
        raise SystemExit("HTTP %s %s\n%s" % (e.code, path, e.read().decode()[:800]))

def login(email, pw):
    return req("POST", "/auth/v1/token?grant_type=password", {"email": email, "password": pw})["access_token"]

def insert(table, rows, token, chunk=200):
    done = 0
    for i in range(0, len(rows), chunk):
        req("POST", "/rest/v1/" + table, rows[i:i+chunk], token, prefer="return=minimal")
        done += len(rows[i:i+chunk])
        print("    %s: %d/%d" % (table, done, len(rows)), end="\r")
    print("    %s: %d แถว" % (table, len(rows)) + " " * 20)

# ---------- helpers ----------
def load(name):
    with io.open(os.path.join(HERE, name), encoding="utf-8-sig", newline="") as fh:
        return list(csv.reader(fh))

def s(v):
    v = (v or "").strip()
    return v or None

def date(v):
    """ชีทใช้ D/M/YYYY (ค.ศ.) -> ISO. คืน None ถ้าไม่ใช่วันที่"""
    v = (v or "").strip()
    m = re.fullmatch(r"(\d{1,2})/(\d{1,2})/(\d{4})", v)
    if not m: return None
    d, mo, y = int(m.group(1)), int(m.group(2)), int(m.group(3))
    if y > 2400: y -= 543          # เผื่อมีแถวที่กรอกเป็น พ.ศ.
    if not (1 <= mo <= 12 and 1 <= d <= 31): return None
    return "%04d-%02d-%02d" % (y, mo, d)

def num(v):
    v = (v or "").strip().replace(",", "")
    if not v or v == "-": return None
    m = re.fullmatch(r"-?\d+(\.\d+)?", v)
    return float(m.group(0)) if m else None

def integer(v):
    n = num(v)
    return int(n) if n is not None else None

def boolean(v):
    v = (v or "").strip().upper()
    return True if v == "TRUE" else (False if v == "FALSE" else None)

def link(v):
    """คอลัมน์ลิงก์บางแถวเป็น TRUE/FALSE (checkbox เก่า) -> ทิ้ง"""
    v = (v or "").strip()
    if not v or v.upper() in ("TRUE", "FALSE"): return None
    return v

# ---------- main ----------
def main():
    token = login("hauslivingestate@gmail.com", os.environ["HAUS_ADMIN_PW"])
    print("login ok\n")

    # แผนที่ชื่อเล่น -> employee_code
    emps = req("GET", "/rest/v1/main_1_hr?select=employee_code,nickname", None, token)
    NICK = {e["nickname"]: e["employee_code"] for e in emps if e.get("nickname")}
    NICK["Stone Bangyai"] = NICK["Stone"]        # ชื่อเพี้ยนในชีท
    NICK["Stone+Pup"] = NICK["Stone"]
    def emp(v):
        return NICK.get((v or "").strip())

    zones = req("GET", "/rest/v1/zone?select=zone_id,name_eng,name_thai", None, token)
    ZBY_EN = {z["name_eng"]: z["zone_id"] for z in zones if z.get("name_eng")}
    ZBY_TH = {z["name_thai"]: z["zone_id"] for z in zones if z.get("name_thai")}
    def zone(v):
        v = (v or "").strip()
        return ZBY_EN.get(v) or ZBY_TH.get(v)

    PROP = {p["name"] for p in req("GET", "/rest/v1/property_type?select=name", None, token)}
    DIRS = {d["name"] for d in req("GET", "/rest/v1/direction?select=name", None, token)}
    POSN = {p["name"] for p in req("GET", "/rest/v1/unit_position?select=name", None, token)}
    COND = {c["name"] for c in req("GET", "/rest/v1/unit_condition?select=name", None, token)}
    PREM = {p["name"] for p in req("GET", "/rest/v1/price_remark?select=name", None, token)}
    LSTA = {x["name"] for x in req("GET", "/rest/v1/listing_status?select=name", None, token)}
    LTYP = {x["name"] for x in req("GET", "/rest/v1/listing_type?select=name", None, token)}
    LPOT = {x["name"] for x in req("GET", "/rest/v1/listing_potential?select=name", None, token)}
    CLOSE = {x["name"] for x in req("GET", "/rest/v1/close_type?select=name", None, token)}
    ACTS = {a["name"] for a in req("GET", "/rest/v1/action_type?select=name", None, token)}
    POT = {x["name"] for x in req("GET", "/rest/v1/potential?select=name", None, token)}
    LEADST = {x["name"] for x in req("GET", "/rest/v1/lead_status?select=name", None, token)}
    STAGE = {x["name"] for x in req("GET", "/rest/v1/pipeline_stage?select=name", None, token)}
    LEADTY = {x["name"] for x in req("GET", "/rest/v1/lead_type?select=name", None, token)}
    only = lambda v, allowed: v if (v in allowed) else None

    # ===== 1) โครงการ =====
    print("1) โครงการ")
    rows = load("Database Sheets - Project.csv"); H = [h.strip() for h in rows[0]]
    P = lambda r, n: r[H.index(n)] if H.index(n) < len(r) else ""
    projects, seen_pid, thai2pid = [], set(), {}
    for r in rows[1:]:
        pid = s(P(r, "Project ID"))
        if not pid or pid in seen_pid: continue
        seen_pid.add(pid)
        th = s(P(r, "Project Name (Thai)"))
        if th and th not in thai2pid: thai2pid[th] = pid
        projects.append({
            "project_id": pid,
            "project_name_eng": s(P(r, "Project Name (Eng)")),
            "project_name_thai": th,
            "property_type": only(s(P(r, "Property Type")), PROP),
            "zone": zone(P(r, "Zone")),
            "total_units": integer(P(r, "จำนวนยูนิต")),
            "phases": integer(P(r, "กี่เฟส")),
            "unit_types": s(P(r, "ประเภท Type ยูนิต")),
            "material": s(P(r, "วัสดุ")),
            "floor_to_ceiling": s(P(r, "Floor to c")),
            "project_age": s(P(r, "อายุโครงการ")),
            "facilities": s(P(r, "ส่วนกลาง")),
            "common_fee": num(P(r, "ค่าส่วนกลาง")),
            "juristic": s(P(r, "นิติบุคคล")),
            "juristic_collect_pct": num(P(r, "นิติเก็บค่าส่วนกลางได้กี่ %")),
            "extra_parking_fee": num(P(r, "จอดเกินต้องเสียคันละเท่าไหร ?")),
            "rental_price_in_project": s(P(r, "ราคาปล่อยเช่าในโครงการ")),
            "flooding": boolean(P(r, "น้ำท่วมขังหรือไม่ ?")),
            "resident_occupation": s(P(r, "อาชีพลูกบ้าน")),
            "project_sold_price": s(P(r, "ราคาจบโครงการ")),
            "pros": s(P(r, "ข้อดี")), "cons": s(P(r, "ข้อเสีย")),
            "sales_id": emp(P(r, "Sales Created By")),
            "date_created": date(P(r, "Date Created")),
        })
    insert("main_3_property_detail", projects, token)

    # ===== 2) เจ้าของ + ทรัพย์ =====
    print("2) ทรัพย์ + เจ้าของ")
    rows = load("Database Sheets - All Listings.csv"); H = [h.strip() for h in rows[0]]
    hi = {h: i for i, h in enumerate(H)}
    def C(r, n):
        i = hi.get(n)
        return r[i] if i is not None and i < len(r) else ""
    OWN_PHONE = [h for h in H if h.startswith("Owner's Phone")][0]
    OWN_LINE = [h for h in H if h.startswith("Owner's LINE")][0]
    D = [r for r in rows[1:] if s(C(r, "Listing ID"))]

    # เจ้าของ: ยุบซ้ำด้วย (ชื่อ, เบอร์)
    owners, okey = [], {}
    for r in D:
        n, p = s(C(r, "Owner's Name")), s(C(r, OWN_PHONE))
        if not n: continue
        k = (n, p)
        if k not in okey:
            okey[k] = len(owners) + 1
            owners.append({"owner_name": n, "owner_phone": p, "owner_line": s(C(r, OWN_LINE))})
    created = req("POST", "/rest/v1/main_2_owner", owners, token, prefer="return=representation")
    print("    main_2_owner: %d แถว" % len(created))
    oid = {}
    for row, rec in zip(owners, created):
        oid[(row["owner_name"], row["owner_phone"])] = rec["owner_id"]

    # Listing ID ซ้ำ -> ขยับเลข
    used = set()
    def uniq_id(lid):
        if lid not in used:
            used.add(lid); return lid
        m = re.fullmatch(r"([A-Z]+)(\d+)", lid)
        if not m:
            i = 2
            while "%s-%d" % (lid, i) in used: i += 1
            used.add("%s-%d" % (lid, i)); return "%s-%d" % (lid, i)
        pre, digits = m.group(1), m.group(2)
        n = int(digits) + 1
        while "%s%0*d" % (pre, len(digits), n) in used: n += 1
        new = "%s%0*d" % (pre, len(digits), n)
        used.add(new); return new

    listings, moved = [], []
    for r in D:
        raw = s(C(r, "Listing ID"))
        lid = uniq_id(raw)
        if lid != raw: moved.append((raw, lid))
        th = s(C(r, "Project Name (Eng)"))     # ชีทใส่ชื่อไทยไว้ในช่องนี้
        own = (s(C(r, "Owner's Name")), s(C(r, OWN_PHONE)))
        listings.append({
            "listing_id": lid,
            "date_created": date(C(r, "Date")),
            "project_id": thai2pid.get(th),
            "listing_status": only(s(C(r, "Listing Status")), LSTA),
            "potential": only(s(C(r, "Potential")), LPOT),
            "sign": boolean(C(r, "Sign")), "vdo": boolean(C(r, "VDO")),
            "ddproperty_link": link(C(r, "Ddproperty Link")),
            "livinginsider_link": link(C(r, "Livinginsider Link")),
            "propertyhub_link": link(C(r, "Facebook Link")),
            "old_price": num(C(r, "Old Price")), "new_price": num(C(r, "New Price")),
            "update_remark": s(C(r, "Update Remark")),
            "last_match_remark": s(C(r, "Last Match Remark")),
            "buyer_persona": s(C(r, "Buyer Persona")),
            "hook": s(C(r, "Buyer Persona")),      # Ben: hook เอามาจาก Buyer Persona
            "owner_focus": boolean(C(r, "Owner Focus")),
            "listing_type": only(s(C(r, "Listing Type")), LTYP),
            "unit_no": s(C(r, "Unit no.")),
            "owner_id": oid.get(own),
            "owner_talk_last_date": date(C(r, "วันที่ Owner Talk ล่าสุด")),
            "activity_comment": s(C(r, "Activity Comment")),
            "property_type": only(s(C(r, "Property Type")), PROP),
            "in_out_project": s(C(r, "ใน/นอกโครงการ")) if s(C(r, "ใน/นอกโครงการ")) in ("ในโครงการ", "นอกโครงการ") else None,
            "road_soi": s(C(r, "ชื่อถนน/ซอย")),
            "zone": zone(C(r, "Zone")),
            "bed": integer(C(r, "Bed")), "bath": num(C(r, "Bath")),
            "area_rai": num(C(r, "ไร่")), "area_ngan": num(C(r, "งาน")),
            "area_wa": num(C(r, "วา")), "area_sqm": num(C(r, "ตรม. / ใช้สอย")),
            "floor": s(C(r, "ชั้น")),
            # 4 คอลัมน์ที่กรอกผิดช่อง -> เอาเฉพาะค่าที่อยู่ถูกช่องจริง (Ben)
            "direction": only(s(C(r, "ทิศ")), DIRS),
            "unit_position": only(s(C(r, "ตำแหน่ง")), POSN),
            "built_year": None,
            "parking": integer(C(r, "Parking")),
            "asking_price": num(C(r, "Asking Price")),
            "rental_price": num(C(r, "Rental Price")),
            "price_remark": only(s(C(r, "Price Remark")), PREM),
            "remark": s(C(r, "Remark")),
            "photo_album_link": link(C(r, "Photo Album Link")),
            "link_location": link(C(r, "Link Location")),
            "unit_condition": only(s(C(r, "Unit Condition")), COND),
            "last_match": s(C(r, "Last Match")),
            "last_match_type": only(s(C(r, "Last Match Type")), CLOSE),
            "sale_id": emp(C(r, "Created By")),
            "marketing_report": link(C(r, "Marketing Report")),
            "dd_boost": boolean(C(r, "DD Boost")), "lv_boost": boolean(C(r, "LV Boost")),
            "fb_repost": boolean(C(r, "FB Repost")),
            # ต้องประกาศไว้ทุกแถว — PostgREST ไม่รับ batch ที่คีย์ไม่เท่ากัน
            "common_fee_note": None, "common_fee_rate": None, "common_fee_unit": None,
        })
        # อายุ -> ปีที่สร้าง (เฉพาะแถวที่กรอกถูกช่อง)
        m = re.fullmatch(r"(\d+)\s*ปี\s*", (C(r, "อายุ") or "").strip())
        if m and listings[-1]["date_created"]:
            listings[-1]["built_year"] = int(listings[-1]["date_created"][:4]) - int(m.group(1))
        # ส่วนกลาง -> เรต (เฉพาะแถวที่เป็นตัวเลข/บาทจริง)
        fee = (C(r, "ส่วนกลาง") or "").strip()
        if fee and (("บาท" in fee) or re.fullmatch(r"[\d,\.]+", fee)):
            listings[-1]["common_fee_note"] = fee
            mm = re.search(r"([\d,\.]+)", fee)
            if mm and "บาท" in fee:
                listings[-1]["common_fee_rate"] = num(mm.group(1))
                listings[-1]["common_fee_unit"] = "per_wa_month"
    insert("main_4_listing_database", listings, token, chunk=100)
    print("    Listing ID ที่ขยับเพราะซ้ำ:", moved)

    # ===== 3) Lead (buyer_focus) =====
    print("3) Lead")
    rows = load("Database Sheets - buyer_focus.csv"); H = [h.strip() for h in rows[0]]
    hi = {h: i for i, h in enumerate(H)}
    B = [r for r in rows[1:] if s(r[hi["Lead ID"]])]
    lid_seen, leads = set(), []
    for r in B:
        g = lambda n: r[hi[n]] if hi[n] < len(r) else ""
        lead_id = s(g("Lead ID"))
        # ชีทใช้ Lead ID ซ้ำหลายแถว -> ต่อ suffix ให้ไม่ชน
        base, k = lead_id, 1
        while lead_id in lid_seen:
            k += 1; lead_id = "%s-%d" % (base, k)
        lid_seen.add(lead_id)
        # คอลัมน์ 2-7 เหลื่อม 1 ช่อง — จับคู่ใหม่ตามความหมายจริง
        leads.append({
            "lead_id": lead_id,
            "date_received": date(g("Date Received")),
            "listing_code": s(g("Listing Code")),
            "potential": only(s(r[2]), POT),
            "lead_status": only(s(r[3]), LEADST),
            "interested": s(r[4]),
            "lead_name": s(r[5]),
            "phone": s(r[6]),
            "admin_remark": s(r[7]),
            "line_id": s(g("LINE ID")),
            "budget": num(g("Budget")),
            "pipeline_stage": only(s(g("Pipeline Stage")), STAGE),
            "last_follow_date": date(g("วันที่ Follow ล่าสุด")),
            "activity_comment": s(g("Activity Comment")),
            "commission": num(g("Commission")),
            "closing_date": date(g("Closing Date")),
            "transfer_date": date(g("Transfer Date")),
            "case_closing_remark": s(g("Case Closing Remark")),
            "complete": boolean(g("Complete")), "confirm": boolean(g("Confirm")),
            "sale_id": emp(g("Created By")),
            "lead_type": only(s(g("Lead Type")), LEADTY),
        })
    valid_listing = {l["listing_id"] for l in listings}
    for l in leads:
        if l["listing_code"] and l["listing_code"] not in valid_listing:
            l["listing_code"] = None       # ไม่มีทรัพย์นั้นจริง -> ปล่อยว่าง ไม่ให้ FK ล้ม
    insert("main_6_buyer_crm", leads, token, chunk=200)

    # ===== 4) Last Match =====
    print("4) Last Match")
    rows = load("Database Sheets - Last Match.csv"); H = [h.strip() for h in rows[0]]
    hi = {h: i for i, h in enumerate(H)}
    M, mseen = [], set()
    for r in rows[1:]:
        g = lambda n: r[hi[n]] if hi[n] < len(r) else ""
        mid = s(g("Last Match ID"))
        if not mid or emp(g("By")) is None: continue      # ข้ามแถว Test
        while mid in mseen: mid += "x"
        mseen.add(mid)
        sq = g("Sq.wa / Sq.m")
        M.append({
            "last_match_id": mid, "sale_id": emp(g("By")),
            "close_type": only(s(g("Type")), CLOSE),
            "project_name": s(g("Projects Name")),
            "property_type": only(s(g("Property Type")), PROP),
            "zone": zone(g("Zone")),
            "sq_wa": num((sq or "").split("/")[0]),
            "sq_m": num((sq or "").split("/")[1]) if "/" in (sq or "") else None,
            "last_match_price": num(g("Last Match Price")),
            "last_match_remark": s(g("Last Match Remark")),
            "buyer_persona": s(g("Buyer Persona")),
            "date_created": date(g("Date Created")),
        })
    insert("main_7_last_match", M, token)

    # ===== 5) Actions -> activities =====
    print("5) กิจกรรม")
    rows = load("Database Sheets - Action.csv"); H = [h.strip() for h in rows[0]]
    hi = {h: i for i, h in enumerate(H)}
    ALIAS = {"Visit": "Owner Visit", "Showing": "Show", "Closing": "Close",
             "อื่นๆ (ระบุ Remark)": "อื่นๆ", "ถ่าย": "ถ่ายรูป", "เปลี่ยนน้ำ,ไฟ": "อื่นๆ",
             "ทิศเหนือ": "อื่นๆ", "แจ้งวัฒนะ": "อื่นๆ", "รีวิวจาก": "อื่นๆ"}
    acts, skipped = [], Counter()
    for r in rows[1:]:
        g = lambda n: r[hi[n]] if hi[n] < len(r) else ""
        d, who = date(g("Date")), emp(g("Sale Name"))
        a = s(g("Action")); a = ALIAS.get(a, a)
        if not (d and who and a in ACTS):
            skipped[a or "(ว่าง)"] += 1; continue
        acts.append({"employee_code": who, "action": a, "activity_date": d,
                     "count": max(1, integer(g("จำนวน")) or 1)})
    insert("activities", acts, token, chunk=400)
    if skipped: print("    ข้าม:", skipped.most_common(8))
    print("\nเสร็จแล้ว")

main()
