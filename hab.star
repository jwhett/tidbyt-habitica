load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("encoding/json.star", "json")

author = "24f2bb71-90b3-4cbc-8c49-231a214f7a60"
app_name = "tidbyt-habitica"
habitica_profile_url = "https://habitica.com/api/v3/members/%s" % author


def get_habitica_profile(url):
    headers = {"X-Client": "%s-%s" % (author, app_name), "X-API-User": author}

    rep = http.get(url, headers=headers)
    if rep.status_code != 200:
        fail("Habitica request failed with status %d", rep.status_code)

    return rep.json()


def main():
    # Profile cache.
    cached_profile = cache.get("user_profile")
    if cached_profile != None:
        print("Cache hit! Using cached data.")
        user_profile = json.decode(cached_profile)
    else:
        print("Cache miss. Fetching new profile data.")
        # Fetch the profile.
        user_profile = get_habitica_profile(habitica_profile_url)
        cache.set("user_profile", json.encode(user_profile), ttl_seconds=30)

    # Separate the fields we want.
    name = user_profile["data"]["profile"]["name"]
    current_exp = user_profile["data"]["stats"]["exp"]
    exp_for_next_lvl = user_profile["data"]["stats"]["toNextLevel"]
    current_hp = user_profile["data"]["stats"]["hp"]
    max_hp = user_profile["data"]["stats"]["maxHealth"]
    current_mp = user_profile["data"]["stats"]["mp"]
    max_mp = user_profile["data"]["stats"]["maxMP"]

    # Render the result.
    return render.Root(
        child = render.Text("User: %s" % name)
    )
