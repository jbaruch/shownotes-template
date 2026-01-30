---
layout: default
---

<div class="home-page">
    <header class="hero-section" {% if site.hero_background %}style="--hero-bg-image: url('{{ site.hero_background }}');"{% endif %}>
        {% comment %} Smart avatar logic: GitHub > custom avatar_url {% endcomment %}
        {% if site.speaker %}
        {% assign avatar_url = "" %}
        {% if site.speaker.social.github and site.speaker.social.github != "" %}
            {% assign avatar_url = "https://avatars.githubusercontent.com/" | append: site.speaker.social.github %}
        {% elsif site.speaker.avatar_url and site.speaker.avatar_url != "" %}
            {% assign avatar_url = site.speaker.avatar_url %}
        {% endif %}
        
        {% if avatar_url != "" %}
        <div class="hero-image">
            <img src="{{ avatar_url }}" alt="{{ site.speaker.display_name }}" class="author-avatar">
        </div>
        {% endif %}
        {% endif %}
        <div class="hero-content">
            {% if site.speaker and site.speaker.display_name and site.speaker.display_name != "" %}
                <h1>{{ site.speaker.display_name }}</h1>
            {% elsif site.speaker and site.speaker.name and site.speaker.name != "" %}
                <h1>{{ site.speaker.name }}</h1>
            {% else %}
                <h1>Speaker</h1>
            {% endif %}
            {% if site.speaker and site.speaker.bio and site.speaker.bio != "" %}
                <p class="hero-description">{{ site.speaker.bio }}</p>
            {% endif %}

            {% assign all_talks = site.talks | default: empty %}
            {% assign talk_count = all_talks.size %}
            {% assign video_count = 0 %}
            {% for talk in all_talks %}
                {% if talk.extracted_video %}
                    {% assign video_count = video_count | plus: 1 %}
                {% endif %}
            {% endfor %}

            {% if talk_count > 0 %}
            <div class="hero-stats">
                <div class="hero-stat">
                    <span class="hero-stat__number">{{ talk_count }}</span>
                    <span class="hero-stat__label">Presentations</span>
                </div>
                {% if video_count > 0 %}
                <div class="hero-stat">
                    <span class="hero-stat__number">{{ video_count }}</span>
                    <span class="hero-stat__label">Recorded</span>
                </div>
                {% endif %}
            </div>
            {% endif %}

            {% if site.speaker and site.speaker.social %}
            {% comment %} Check if any social media links are present {% endcomment %}
            {% assign has_social = false %}
            {% assign linkedin_exists = false %}
            {% assign x_exists = false %}
            {% assign github_exists = false %}
            {% assign mastodon_exists = false %}
            {% assign bluesky_exists = false %}
            
            {% if site.speaker.social.linkedin and site.speaker.social.linkedin != "" %}
                {% assign has_social = true %}
                {% assign linkedin_exists = true %}
            {% endif %}
            {% if site.speaker.social.x and site.speaker.social.x != "" %}
                {% assign has_social = true %}
                {% assign x_exists = true %}
            {% endif %}
            {% if site.speaker.social.github and site.speaker.social.github != "" %}
                {% assign has_social = true %}
                {% assign github_exists = true %}
            {% endif %}
            {% if site.speaker.social.mastodon and site.speaker.social.mastodon != "" %}
                {% assign has_social = true %}
                {% assign mastodon_exists = true %}
            {% endif %}
            {% if site.speaker.social.bluesky and site.speaker.social.bluesky != "" %}
                {% assign has_social = true %}
                {% assign bluesky_exists = true %}
            {% endif %}
            
            {% if has_social %}
            <div class="speaker-social-links">
                {% if linkedin_exists %}
                <a href="https://linkedin.com/in/{{ site.speaker.social.linkedin }}" target="_blank" rel="noopener noreferrer" class="social-link linkedin" aria-label="LinkedIn">
                    <svg viewBox="0 0 24 24" class="social-icon"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg>
                </a>
                {% endif %}
                {% if x_exists %}
                <a href="https://x.com/{{ site.speaker.social.x }}" target="_blank" rel="noopener noreferrer" class="social-link x" aria-label="X (formerly Twitter)">
                    <svg viewBox="0 0 24 24" class="social-icon"><path d="M18.901 1.153h3.68l-8.04 9.19L24 22.846h-7.406l-5.8-7.584-6.638 7.584H.474l8.6-9.83L0 1.154h7.594l5.243 6.932ZM17.61 20.644h2.039L6.486 3.24H4.298Z"/></svg>
                </a>
                {% endif %}
                {% if github_exists %}
                <a href="https://github.com/{{ site.speaker.social.github }}" target="_blank" rel="noopener noreferrer" class="social-link github" aria-label="GitHub">
                    <svg viewBox="0 0 24 24" class="social-icon"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.30.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
                </a>
                {% endif %}
                {% if mastodon_exists %}
                <a href="{{ site.speaker.social.mastodon }}" target="_blank" rel="noopener noreferrer" class="social-link mastodon" aria-label="Mastodon">
                    <svg viewBox="0 0 24 24" class="social-icon"><path d="M23.268 5.313c-.35-2.578-2.617-4.61-5.304-5.004C17.51.242 15.792 0 11.813 0h-.03c-3.98 0-4.835.242-5.288.309C3.882.692 1.496 2.518.917 5.127.64 6.412.61 7.837.661 9.143c.074 1.874.088 3.745.26 5.611.118 1.24.325 2.47.62 3.68.55 2.237 2.777 4.098 4.96 4.857 2.336.792 4.849.923 7.256.38.265-.061.527-.132.786-.213.585-.184 1.27-.39 1.774-.753a.057.057 0 0 0 .023-.043v-1.809a.052.052 0 0 0-.02-.041.053.053 0 0 0-.046-.01 20.282 20.282 0 0 1-4.709.545c-2.73 0-3.463-1.284-3.674-1.818a5.593 5.593 0 0 1-.319-1.433.053.053 0 0 1 .066-.054c1.517.363 3.072.546 4.632.546.376 0 .75 0 1.125-.01 1.57-.044 3.224-.124 4.768-.422.038-.008.077-.015.11-.024 2.435-.464 4.753-1.92 4.989-5.604.008-.145.03-1.52.03-1.67.002-.512.167-3.63-.024-5.545zm-3.748 9.195h-2.561V8.29c0-1.309-.55-1.976-1.67-1.976-1.23 0-1.846.79-1.846 2.35v3.403h-2.546V8.663c0-1.56-.617-2.35-1.848-2.35-1.112 0-1.668.668-1.67 1.977v6.218H4.822V8.102c0-1.31.337-2.35 1.011-3.12.696-.77 1.608-1.164 2.74-1.164 1.311 0 2.302.5 2.962 1.498l.638 1.06.638-1.06c.66-.999 1.65-1.498 2.96-1.498 1.13 0 2.043.395 2.74 1.164.675.77 1.012 1.81 1.012 3.12z"/></svg>
                </a>
                {% endif %}
                {% if bluesky_exists %}
                <a href="https://bsky.app/profile/{{ site.speaker.social.bluesky }}" target="_blank" rel="noopener noreferrer" class="social-link bluesky" aria-label="Bluesky">
                    <svg viewBox="0 0 24 24" class="social-icon"><path d="M12 10.8c-1.087-2.114-4.046-6.053-6.798-7.995C2.566.944 1.561 1.266.902 1.565.139 1.908 0 3.08 0 3.768c0 .69.378 5.65.624 6.479.815 2.736 3.713 3.66 6.383 3.364.136-.02.275-.039.415-.056-.138.022-.276.04-.415.056-2.67-.296-5.568.628-6.383 3.364C.378 17.902 0 22.861 0 23.55c0 .688.139 1.86.902 2.203.659.299 1.664.621 4.3-1.24C7.954 22.571 10.913 18.632 12 16.518c1.087 2.114 4.046 6.053 6.798 7.995 2.636 1.861 3.641 1.539 4.3 1.24.763-.343.902-1.515.902-2.203 0-.689-.378-5.648-.624-6.477-.815-2.736-3.713-3.66-6.383-3.364-.139.016-.277.034-.415.056.138-.017.276-.036.415-.056 2.67.296 5.568-.628 6.383-3.364.246-.829.624-5.789.624-6.479 0-.688-.139-1.86-.902-2.203-.659-.299-1.664-.621-4.3 1.24C16.046 4.747 13.087 8.686 12 10.8z"/></svg>
                </a>
                {% endif %}
            </div>
            {% endif %}
            {% endif %}
        </div>
    </header>

    {% assign talks = site.talks | default: empty %}
    {% unless talks == empty %}
      {% assign talks = talks | sort: 'extracted_date' | reverse %}
    {% endunless %}

    {% comment %} Conference logo strip - use curated list or fall back to most recent {% endcomment %}
    {% assign conferences = "" | split: "" %}
    {% if site.featured_conferences and site.featured_conferences.size > 0 %}
        {% comment %} Use manually curated conference list {% endcomment %}
        {% assign conferences = site.featured_conferences %}
    {% else %}
        {% comment %} Fall back to unique conferences from most recent talks {% endcomment %}
        {% for talk in talks %}
            {% if talk.extracted_conference %}
                {% unless conferences contains talk.extracted_conference %}
                    {% assign conferences = conferences | push: talk.extracted_conference %}
                {% endunless %}
            {% endif %}
        {% endfor %}
    {% endif %}

    {% if conferences.size > 0 %}
    <div class="logo-strip">
        <p class="logo-strip__label">Featured at</p>
        <div class="logo-strip__logos">
            {% for conf in conferences limit: 6 %}
            <span class="logo-strip__logo">{{ conf }}</span>
            {% endfor %}
        </div>
    </div>
    {% endif %}
    {% if talks.size > 0 %}
        {% comment %} Filter for talks with preview resources to feature them {% endcomment %}
        {% assign talks_with_previews = '' | split: '' %}
        {% for talk in talks %}
            {% if talk.extracted_slides or talk.extracted_video or talk.thumbnail_url %}
                {% assign talks_with_previews = talks_with_previews | push: talk %}
            {% endif %}
        {% endfor %}

        {% assign recent_talks = talks_with_previews | slice: 0, 3 %}

        {% if recent_talks.size > 0 %}
        <section class="featured-talks">
            <h2>Highlighted Presentations</h2>
            <div class="featured-talks-grid">
                {% for talk in recent_talks %}
                  <article class="featured-talk-card">
                    <a href="{{ talk.url | relative_url }}" class="featured-talk-card-link">
                    {% comment %} Generate thumbnail based on filename slug {% endcomment %}
                    {% assign talk_slug = talk.path | split: '/' | last | replace: '.md', '' %}
                    {% assign thumbnail_path = '/assets/images/thumbnails/' | append: talk_slug | append: '-thumbnail.png' | relative_url %}
                    {% assign placeholder_url = '/assets/images/placeholder-thumbnail.svg' | relative_url %}
                    
                    <div class="featured-thumbnail">
                        <img src="{{ thumbnail_path }}" alt="{{ talk.extracted_title | default: talk.title | escape }}" class="thumbnail-image" loading="lazy" data-fallback="{{ placeholder_url }}" onerror="this.onerror=null;this.src=this.dataset.fallback;">
                    </div>

                    <div class="featured-info">
                        {% comment %}WARNING: If extracted_title is missing, plugin may not be running{% endcomment %}
                        {% if talk.extracted_title %}
                        <h3>{{ talk.extracted_title }}</h3>
                        {% else %}
                        {% comment %}Humanize slugified title as fallback{% endcomment %}
                        <h3>{{ talk.title | replace: "-", " " | capitalize }}</h3>
                        {% endif %}
                        <div class="talk-meta">
                            {% if talk.extracted_conference %}
                            <span class="meta-item conference-name">
                                {{ talk.extracted_conference }}
                            </span>
                            {% elsif talk.conference %}
                            {% comment %}WARNING: Using frontmatter conference as fallback{% endcomment %}
                            <span class="meta-item conference-name">
                                {{ talk.conference }}
                            </span>
                            {% endif %}
                            {% if talk.extracted_date %}
                            <time class="meta-item date" datetime="{{ talk.extracted_date | date_to_xmlschema }}">
                                {{ talk.extracted_date | date: "%B %d, %Y" }}
                            </time>
                            {% elsif talk.date %}
                            {% comment %}WARNING: Using page date as fallback{% endcomment %}
                            <time class="meta-item date" datetime="{{ talk.date | date_to_xmlschema }}">
                                {{ talk.date | date: "%B %d, %Y" }}
                            </time>
                            {% endif %}
                            {% if talk.extracted_video %}
                                <span class="meta-item status-badge video-published">
                                    Video Available
                                </span>
                            {% else %}
                                <span class="meta-item status-badge video-pending">
                                    Video Coming Soon
                                </span>
                            {% endif %}
                        </div>
                        {% if talk.extracted_description %}
                            <p class="talk-summary">{{ talk.extracted_description | truncate: 100 }}</p>
                        {% endif %}
                    </div>
                    </a>
                  </article>
                {% endfor %}
            </div>
        </section>
        {% endif %}

        <!-- All Talks Section -->
        {% if talks.size > 0 %}
        <section class="all-talks">
            <h2>All Presentations</h2>
            <div class="talks-list">
                {% for talk in talks %}
                <article class="talk-list-item">
                    <a href="{{ talk.url | relative_url }}" class="talk-list-item-link">
                    {% comment %} Extract slides resource for preview (prioritize slides over video) {% endcomment %}
                    {% assign preview_resource = null %}
                    {% comment %} Generate thumbnail based on filename slug {% endcomment %}
                    {% assign talk_slug = talk.path | split: '/' | last | replace: '.md', '' %}
                    {% assign thumbnail_path = '/assets/images/thumbnails/' | append: talk_slug | append: '-thumbnail.png' | relative_url %}
                    {% assign placeholder_url = '/assets/images/placeholder-thumbnail.svg' | relative_url %}
                    
                        <div class="talk-thumbnail">
                            <img src="{{ thumbnail_path }}" alt="{{ talk.extracted_title | default: talk.title | escape }}" class="thumbnail-image" loading="lazy" data-fallback="{{ placeholder_url }}" onerror="this.onerror=null;this.src=this.dataset.fallback;">
                        </div>
                        
                        <div class="talk-info">
                            {% comment %}WARNING: If extracted_title is missing, plugin may not be running{% endcomment %}
                            {% if talk.extracted_title %}
                            <h3>{{ talk.extracted_title }}</h3>
                            {% else %}
                            {% comment %}Humanize slugified title as fallback{% endcomment %}
                            <h3>{{ talk.title | replace: "-", " " | capitalize }}</h3>
                            {% endif %}
                            <div class="talk-meta">
                                {% if talk.extracted_conference %}
                                <span class="meta-item conference-name">
                                    {{ talk.extracted_conference }}
                                </span>
                                {% elsif talk.conference %}
                                {% comment %}WARNING: Using frontmatter conference as fallback{% endcomment %}
                                <span class="meta-item conference-name">
                                    {{ talk.conference }}
                                </span>
                                {% endif %}
                                {% if talk.extracted_date %}
                                <time class="meta-item date" datetime="{{ talk.extracted_date | date_to_xmlschema }}">
                                    {{ talk.extracted_date | date: "%B %d, %Y" }}
                                </time>
                                {% elsif talk.date %}
                                {% comment %}WARNING: Using page date as fallback{% endcomment %}
                                <time class="meta-item date" datetime="{{ talk.date | date_to_xmlschema }}">
                                    {{ talk.date | date: "%B %d, %Y" }}
                                </time>
                                {% endif %}
                                {% comment %} Video publication status - moved to metadata section {% endcomment %}
                                {% if talk.extracted_video %}
                                    <span class="meta-item status-badge video-published">
                                        Video Available
                                    </span>
                                {% else %}
                                    <span class="meta-item status-badge video-pending">
                                        Video Coming Soon
                                    </span>
                                {% endif %}
                            </div>
                            {% if talk.extracted_description %}
                                <p class="talk-summary">{{ talk.extracted_description | truncate: 120 }}</p>
                            {% endif %}
                        </div>
                    </a>
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
