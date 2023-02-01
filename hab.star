"""
Fetch and render Habitica profile data on Tidbyt.
"""
load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("encoding/json.star", "json")


# API deets
author = "24f2bb71-90b3-4cbc-8c49-231a214f7a60"
app_name = "tidbyt-habitica"
habitica_profile_url = "https://habitica.com/api/v3/members/%s" % author
profile_cache_ttl_seconds = 1800

# Bar deets
bar_height = 3
bar_max_length = 64

# Colors
color_red = "#ff0000ff"
color_yellow = "#ffff00ff"
color_blue = "#0000ffff"


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


def filter_profile_fields(profile_data):
    """
    Filter fields from the profile returned from Habitica API.

    Args:
        profile_data: Dict format of profile data response from Habitica API.
        Note that this is specifically the "data" field of the overall
        profile response from the API.
    
    Returns:
        Dict containing only fields that we're interested in which
        reduces how much space is needed in cache.
    """
    stats = profile_data["stats"]
    return {
        "name": profile_data["profile"]["name"],
        "stats": stats,
        "current_exp": stats["exp"],
        "exp_for_next_lvl": stats["toNextLevel"],
        "exp_percentage": (stats["exp"]/stats["toNextLevel"]),
        "current_hp": stats["hp"],
        "max_hp": stats["maxHealth"],
        "hp_percentage": (stats["hp"]/stats["maxHealth"]),
        "current_mp": stats["mp"],
        "max_mp": stats["maxMP"],
        "mp_percentage": (stats["mp"]/stats["maxMP"]),
    }


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
        user_profile = filter_profile_fields(get_habitica_profile(habitica_profile_url))
        cache.set("user_profile", json.encode(user_profile), ttl_seconds=profile_cache_ttl_seconds)


    # Render the result.
    return render.Root(
        child = render.Column(
            children=[render.Text(user_profile["name"]),
            render.Box(width=int(bar_max_length*user_profile["hp_percentage"]), height=bar_height, color=color_red),
            render.Box(width=int(bar_max_length*user_profile["exp_percentage"]), height=bar_height, color=color_yellow),
            render.Box(width=int(bar_max_length*user_profile["mp_percentage"]), height=bar_height, color=color_blue)
            ]
        )          
    )
