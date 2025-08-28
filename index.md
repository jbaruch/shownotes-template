---
layout: default
title: "Conference Talks & Presentations"
description: "Conference talks, presentations, and show notes with embedded resources"
---

<div class="home-page">
    <header class="hero-section">
        <h1>Conference Talks & Presentations</h1>
        <p class="hero-description">Show notes, resources, and embedded content from conference presentations</p>
    </header>

    {% assign talks = site.talks | sort: 'date' | reverse %}
    {% if talks.size > 0 %}
        <!-- Recent/Featured Talks Section -->
        {% assign recent_talks = talks | limit: 3 %}
        {% if recent_talks.size > 0 %}
        <section class="featured-talks">
            <h2>Recent Presentations</h2>
            <div class="featured-talks-grid">
                {% for talk in recent_talks %}
                <article class="featured-talk-card">
                    {% comment %} Extract preview thumbnail from resources {% endcomment %}
                    {% assign preview_resource = null %}
                    {% if talk.resources %}
                        {% for resource in talk.resources %}
                            {% if resource.type == 'slides' or resource.type == 'video' %}
                                {% assign preview_resource = resource %}
                                {% break %}
                            {% endif %}
                        {% endfor %}
                    {% endif %}

                    {% if preview_resource %}
                    <div class="talk-preview-large">
                        {% include embedded_resource.html resource=preview_resource preview_mode=true size='large' %}
                    </div>
                    {% endif %}

                    <div class="talk-content">
                        <header class="talk-header">
                            <h3><a href="{{ talk.url | relative_url }}">{{ talk.title }}</a></h3>
                            <div class="talk-meta">
                                {% if talk.conference %}
                                <span class="meta-item conference-name">
                                    <span class="meta-icon conference" aria-hidden="true"></span>
                                    {{ talk.conference }}
                                </span>
                                {% endif %}
                                {% if talk.date %}
                                <time class="meta-item" datetime="{{ talk.date | date_to_xmlschema }}">
                                    <span class="meta-icon date" aria-hidden="true"></span>
                                    {{ talk.date | date: "%B %d, %Y" }}
                                </time>
                                {% endif %}
                                {% if talk.status %}
                                <span class="meta-item status-{{ talk.status | downcase }}">
                                    <span class="meta-icon status" aria-hidden="true"></span>
                                    {{ talk.status | capitalize }}
                                </span>
                                {% endif %}
                            </div>
                        </header>

                        {% if talk.description %}
                            <p class="talk-description">{{ talk.description }}</p>
                        {% endif %}

                        {% if talk.resources %}
                            <div class="talk-resources-preview">
                                {% assign grouped_resources = talk.resources | group_by: "type" %}
                                <ul class="resource-types-inline">
                                    {% for group in grouped_resources %}
                                        <li class="resource-type">
                                            <span class="resource-icon resource-icon-{{ group.name }}"></span>
                                            {{ group.name | capitalize }}
                                        </li>
                                    {% endfor %}
                                </ul>
                            </div>
                        {% endif %}

                        <footer class="talk-footer">
                            <a href="{{ talk.url | relative_url }}" class="view-talk-btn">View Talk & Resources →</a>
                        </footer>
                    </div>
                </article>
                {% endfor %}
            </div>
        </section>
        {% endif %}

        <!-- All Other Talks Section -->
        {% assign older_talks = talks | offset: 3 %}
        {% if older_talks.size > 0 %}
        <section class="all-talks">
            <h2>All Presentations</h2>
            <div class="talks-list">
                {% for talk in older_talks %}
                <article class="talk-list-item">
                    {% comment %} Extract preview thumbnail from resources {% endcomment %}
                    {% assign preview_resource = null %}
                    {% if talk.resources %}
                        {% for resource in talk.resources %}
                            {% if resource.type == 'slides' or resource.type == 'video' %}
                                {% assign preview_resource = resource %}
                                {% break %}
                            {% endif %}
                        {% endfor %}
                    {% endif %}

                    {% if preview_resource %}
                    <div class="talk-preview-small">
                        {% include embedded_resource.html resource=preview_resource preview_mode=true size='small' %}
                    </div>
                    {% endif %}

                    <div class="talk-content">
                        <h3><a href="{{ talk.url | relative_url }}">{{ talk.title }}</a></h3>
                        <div class="talk-meta-inline">
                            {% if talk.conference %}
                                <span class="conference">{{ talk.conference }}</span>
                            {% endif %}
                            {% if talk.date %}
                                <time datetime="{{ talk.date | date_to_xmlschema }}">{{ talk.date | date: "%B %Y" }}</time>
                            {% endif %}
                        </div>
                        {% if talk.description %}
                            <p class="talk-summary">{{ talk.description | truncate: 120 }}</p>
                        {% endif %}
                    </div>
                </article>
                {% endfor %}
            </div>
        </section>
        {% endif %}

    {% else %}
        <div class="empty-state">
            <h2>No talks yet</h2>
            <p>Check back soon for conference talks and presentations!</p>
        </div>
    {% endif %}
</div>