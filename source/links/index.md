---
title: 友情链接
comments: false
---

<div id="links">
	<div class="links-content">
		<div class="link-navigation">
			{% for link in site.data.links %}
			<div class="card">
  				<a href="{{ link.site }}" target="_blank">
  					<img class="linkAvatar" src="{{ link.avatar }}"/>
                </a>
  				<div class="card-header">
  					<div>
                        <a href="{{ link.site }}" target="_blank">{{ link.name }}</a>
  						<a href="{{ link.site }}">
                            <span class="focus-links">
                                <i class="fa fa-plus" aria-hidden="true"></i>&nbsp;关注
                            </span>
                        </a>
                    </div>
  					<div class="info" title="{{ link.info }}">{{ link.info }}</div>
  				</div>
			</div>
			{% endfor %}
		</div>
	</div>
</div>