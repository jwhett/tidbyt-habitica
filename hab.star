load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("encoding/json.star", "json")


# API deets
author = "24f2bb71-90b3-4cbc-8c49-231a214f7a60"
app_name = "tidbyt-habitica"
habitica_profile_url = "https://habitica.com/api/v3/members/%s" % author

# Bar deets
bar_height = 3
bar_max_length = 64

# Colors
color_red = "#b30b0b"
color_yellow = "#e7f20c"
color_blue = "#0b0ed9"


def get_habitica_profile(url):
    """
    Use the Habitica API to pull the user's profile.

    Args:
        url: Formatted API URL for the target user.

    Returns:
        Dict of profile response.
    """
    headers = {"X-Client": "%s-%s" % (author, app_name), "X-API-User": author}

    rep = http.get(url, headers=headers)
    if rep.status_code != 200:
        fail("Habitica request failed with status %d", rep.status_code)

    return rep.json()["data"]


def main():
    """
    Pull, cache, and format Habitica Profile for Tidbyt.

    Returns:
        Render object to be displayed by Tidbyt.
    """
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
    name = user_profile["profile"]["name"]
    stats = user_profile["stats"]

    # Stat values
    current_exp = stats["exp"]
    exp_for_next_lvl = stats["toNextLevel"]
    exp_percentage = (current_exp/exp_for_next_lvl)

    current_hp = stats["hp"]
    max_hp = stats["maxHealth"]
    hp_percentage = (current_hp/max_hp)

    current_mp = stats["mp"]
    max_mp = stats["maxMP"]
    mp_percentage = (current_mp/max_mp)

    # Render the result.
    return render.Root(
        child = render.Column(
            children=[render.Text(name),
            render.Box(width=int(bar_max_length*hp_percentage), height=bar_height, color=color_red),
            render.Box(width=int(bar_max_length*exp_percentage), height=bar_height, color=color_yellow),
            render.Box(width=int(bar_max_length*mp_percentage), height=bar_height, color=color_blue)
            ]
        )          
    )
