# You can view the rendered version of this file at:
#   https://buttslol.net/ublock-filters.txt
# from where you can more easily copy and paste filters into your own rulesets.
{
  helpers,
  lib,
  pkgs,
  ...
}: let
  dlist = builtins.concatStringsSep ",";
  discord = dlist ["discord.com" "canary.discord.com" "ptb.discord.com"];
  mastodon = dlist ["tacobelllabs.net"];
  # https://meta.stackexchange.com/a/81383
  stackexchange = dlist [
    "askubuntu.com"
    "mathoverflow.net"
    "serverfault.com"
    "stackoverflow.com"
    "stackexchange.com"
    "stackapps.com"
    "superuser.com"
  ];

  networkFilters = [
    # Disable "Sign in with Google" iframes
    "||accounts.google.com/gsi/$3p"

    # Disable Disqus embeds
    "||disqus.com/embed$subdocument"

    # https://bendodson.com/projects/itunes-artwork-finder/
    # Please do not stare into my soul
    "||bendodson.s3.amazonaws.com/ben-dodson.png$image"

    # Various marketing chat providers
    "||client.crisp.chat$script"
  ];

  cosmeticFilters = {
    ${discord} =
      # Remove visual noise from chat bar
      (builtins.map (s: "##button[aria-label=\"${s}\"]") ["Send a gift" "Open GIF picker" "Open sticker picker"])
      # Remove things that are not direct messages
      ++ (builtins.map (s: "##ul[aria-label=\"Direct Messages\"] li:has(a[href=\"${s}\"])") ["/store" "/shop"]);

    "github.com" = [
      # My email inbox is a better system than GitHub's notifications
      "##notification-indicator"
      # Home page removals
      "##aside div[aria-label=\"Explore repositories\"]"
      "##.dashboard-changelog"
      # Upsell removals
      "##button:has-text(\"GitHub Copilot\")"
      # Achievements have an unexpected "coin flip" animation on hover
      "##body.page-profile div:has(> h2:has-text(/^Achievements$/))"
    ];

    "kagi.com" = [
      # Hide buttons for various AI features
      "##._0_discuss_document"
      "##._0_summarize_link"
      "##._0_summarize_page"
    ];

    ${mastodon} = [
      # Remove inline embed cards in the timelines
      "##.status-card:not(:upward(.detailed-status))"
    ];

    "meet.google.com" = [
      # Remove the "Present" button that I keep misclicking right next to "Join now" when joining a call
      "##div:has(> button:has-text(Join now)) + div:has(> button:has-text(Present))"
    ];

    ${stackexchange} = [
      # Remove annoying cookie consent popup
      "##.js-consent-banner"
      # Remove the most effective distraction machine in existence
      "###hot-network-questions"
      # Remove toxic industury garbage from sidebar
      "###sidebar li:has-text(\"The Overflow Blog\")"
      "###sidebar li:has(a[href*=\"stackoverflow.blog\"])"
    ];

    "twitch.tv" =
      [
        "##.community-points-summary"
        "##nav button:has-text(Get Ad-Free)"
        "##.prime-offers"
      ]
      ++ (builtins.map (s: "##div:has(> button[aria-label=\"${s}\"])") ["Bits" "Get Bits" "Hype Chat"]);

    "youtube.com" = [
      # Hide Yoodles (often-animated commemorative site logos)
      "##ytd-yoodle-renderer"
    ];
  };
in {
  iliana.www.virtualHosts."buttslol.net"."/ublock-filters.txt" = helpers.caddy.serve (pkgs.writeTextDir "ublock-filters.txt" ''
    ! Title: iliana's annoyance list
    ! Expires: 12 hours
    ! License: https://creativecommons.org/publicdomain/zero/1.0/
    ! SPDX-License-Identifier: CC0-1.0

    ! This list isn't meant for public use; at some point I'll get annoyed at something you like.
    ! Generated by https://github.com/iliana/nixos-configs/blob/main/modules/www/ublock-filters.nix

    ${
      builtins.concatStringsSep "\n"
      (networkFilters
        ++ lib.flatten (lib.mapAttrsToList
          (domain: filters: builtins.map (filter: domain + filter) filters)
          cosmeticFilters))
    }
  '');
}
