---
layout: default
title: "Home"
description: "Conference talk show notes and resources"
---

# Welcome to Shownotes

This is a platform for sharing conference talk show notes, resources, and updates.

## Recent Talks

{% assign recent_talks = site.talks | sort: 'date' | reverse | limit: 5 %}
{% if recent_talks.size > 0 %}
<div class="recent-talks">
  {% for talk in recent_talks %}
  <article class="talk-preview">
    <h3><a href="{{ talk.url | relative_url }}">{{ talk.title }}</a></h3>
    <div class="talk-preview-meta">
      <span class="speaker">{{ talk.speaker }}</span>
      <span class="conference">{{ talk.conference }}</span>
      <time class="date">{{ talk.date | date: "%B %d, %Y" }}</time>
    </div>
    {% if talk.description %}
    <p class="talk-preview-description">{{ talk.description }}</p>
    {% endif %}
  </article>
  {% endfor %}
</div>

<p><a href="{{ '/talks/' | relative_url }}">View all talks →</a></p>
{% else %}
<p>No talks available yet. Check back soon!</p>
{% endif %}