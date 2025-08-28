---
layout: default
title: "{{ site.title }}"
description: "{{ site.description }}"
---

<div class="home-page">
    <header class="hero-section" {% if site.hero_background %}style="background-image: linear-gradient(135deg, rgba(99, 102, 241, 0.3) 0%, rgba(79, 70, 229, 0.5) 100%), url('{{ site.hero_background }}');"{% endif %}>
        {% if site.avatar_url %}
        <div class="hero-image">
            <img src="{{ site.avatar_url }}" alt="{{ site.author_name }}" class="author-avatar">
        </div>
        {% endif %}
        <div class="hero-content">
            <h1>Presentations by {{ site.author_name }}</h1>
            <p class="hero-description">{{ site.description }}</p>
        </div>
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
                    {% comment %} Extract slides resource for preview (prioritize slides over video) {% endcomment %}
                    {% assign preview_resource = null %}
                    {% if talk.resources %}
                        {% comment %} First try to find slides {% endcomment %}
                        {% for resource in talk.resources %}
                            {% if resource.type == 'slides' %}
                                {% assign preview_resource = resource %}
                                {% break %}
                            {% endif %}
                        {% endfor %}
                        {% comment %} If no slides found, use video as fallback {% endcomment %}
                        {% if preview_resource == null %}
                            {% for resource in talk.resources %}
                                {% if resource.type == 'video' %}
                                    {% assign preview_resource = resource %}
                                    {% break %}
                                {% endif %}
                            {% endfor %}
                        {% endif %}
                    {% endif %}

                    {% if preview_resource %}
                    <div class="talk-preview-large">
                        {% include embedded_resource.html resource=preview_resource preview_mode=true size='large' talk_url=talk.url %}
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
                            </div>
                        </header>

                        {% if talk.description %}
                            <p class="talk-description">{{ talk.description }}</p>
                        {% endif %}

                        {% comment %} Video publication status {% endcomment %}
                        {% assign has_video = false %}
                        {% for resource in talk.resources %}
                            {% if resource.type == 'video' %}
                                {% assign has_video = true %}
                                {% break %}
                            {% endif %}
                        {% endfor %}
                        
                        <div class="video-status">
                            {% if has_video %}
                                <span class="status-badge video-published">Video Available</span>
                            {% else %}
                                <span class="status-badge video-pending">Video Coming Soon</span>
                            {% endif %}
                        </div>


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
                    {% comment %} Extract slides resource for preview (prioritize slides over video) {% endcomment %}
                    {% assign preview_resource = null %}
                    {% if talk.resources %}
                        {% comment %} First try to find slides {% endcomment %}
                        {% for resource in talk.resources %}
                            {% if resource.type == 'slides' %}
                                {% assign preview_resource = resource %}
                                {% break %}
                            {% endif %}
                        {% endfor %}
                        {% comment %} If no slides found, use video as fallback {% endcomment %}
                        {% if preview_resource == null %}
                            {% for resource in talk.resources %}
                                {% if resource.type == 'video' %}
                                    {% assign preview_resource = resource %}
                                    {% break %}
                                {% endif %}
                            {% endfor %}
                        {% endif %}
                    {% endif %}

                    {% if preview_resource %}
                    <div class="talk-preview-small">
                        {% include embedded_resource.html resource=preview_resource preview_mode=true size='small' talk_url=talk.url %}
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
                        
                        {% comment %} Video publication status {% endcomment %}
                        {% assign has_video = false %}
                        {% for resource in talk.resources %}
                            {% if resource.type == 'video' %}
                                {% assign has_video = true %}
                                {% break %}
                            {% endif %}
                        {% endfor %}
                        
                        <div class="video-status">
                            {% if has_video %}
                                <span class="status-badge video-published">Video Available</span>
                            {% else %}
                                <span class="status-badge video-pending">Video Coming Soon</span>
                            {% endif %}
                        </div>
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