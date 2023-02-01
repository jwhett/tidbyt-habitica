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
outside_bar_height = 5
inside_bar_height = outside_bar_height-2
outside_bar_max_length = 64
inside_bar_max_length = outside_bar_max_length-2
inside_bar_padding = (1,1,0,0) # (left, top, right, bottom)

# Colors
color_white = "#ffffffff"
color_faded_white = "#ffffffee"
color_red = "#ff0000ff"
color_faded_red = "#ff000055"
color_yellow = "#ffff00ff"
color_faded_yellow = "#ffff0055"
color_blue = "#0000ffff"
color_faded_blue = "#0000ff55"
color_pale_green = "#00ff99ff"

# Default colors
default_border_color = color_white
default_inner_fg_color = color_white
default_inner_bg_color = color_faded_white


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


def stat_bar(val, inner_fg_color=default_inner_fg_color, inner_bg_color=default_inner_bg_color, border_color=default_border_color):
    """
    Build a stacked stat bar Widget.

    Args:
        val: Value expected to be the float percentage of the bar
        to be filled.
        inner_fg_color: Foreground color of the inner bar. Width
        of bar is determined by val.
        inner_bg_color: Background color of the inner bar. This
        is shown in the negative space of the inner bar representing
        the "missing" portion.
        border_color: Color of the border. Technically rendered
        behind both inner bars.
    
    Returns:
        Stacked Widget of three Boxes. Inner bars are padded to fit
        within the border.
    """
    return render.Stack(children=[
                    render.Box(width=outside_bar_max_length, height=outside_bar_height, color=border_color),
                    render.Padding(
                        render.Box(width=inside_bar_max_length, height=inside_bar_height, color=inner_bg_color),
                        pad=inside_bar_padding,
                    ),
                    render.Padding(
                        render.Box(width=int(val*inside_bar_max_length), height=inside_bar_height, color=inner_fg_color),
                        pad=inside_bar_padding,
                    ),
                ])

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
            children=[
                render.Text(user_profile["name"], font="6x13", color=color_pale_green),
                stat_bar(user_profile["hp_percentage"], inner_fg_color=color_red, inner_bg_color=color_faded_red),
                stat_bar(user_profile["exp_percentage"], inner_fg_color=color_yellow, inner_bg_color=color_faded_yellow),
                stat_bar(user_profile["mp_percentage"], inner_fg_color=color_blue, inner_bg_color=color_faded_blue),
            ]
        )
    )
