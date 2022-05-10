fmts = [ 
    '%Y-%m-%dT%H:%M:%S',
    '%Y-%m-%dT%H:%M:%SZ', 
    '%Y-%m-%dT%H:%M:%SUTC'
    ]

dt_str = '2021-12-31 04:41:52'
dt.strptime(dt_str, fmt[2])

dt_ts.utcfromtimestamp(dt_str)

ts = int(time.mktime(dt.strptime(dt_str, fmts[0]).timetuple()))
dt.utcfromtimestamp(ts).replace(tzinfo=pytz.utc).astimezone(local_tz)
ts.utcfromtimestamp(dt_str)
ts = replace(tzinfo=pytz.utc)
local_tz = get_localzone()


cmp = dt.utcfromtimestamp(ts).replace(tzinfo=pytz.utc).astimezone(local_tz)
dt_naive = dt.strptime(1640954512, fmt)
dt_naive = dt.strptime(1640954512.0, fmt)

