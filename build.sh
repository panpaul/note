set -x
rm -rf themes/next
git clone https://github.com/next-theme/hexo-theme-next --branch v8.11.1 themes/next
cp themes/_config.yml themes/next/
cp themes/microsoft-clarity.njk themes/next/layout/_third-party/analytics/
sed -i "/commonweal/ a\  links: 友情链接" themes/next/languages/zh-CN.yml
sed -i "/commonweal/ a\  links: Links" themes/next/languages/en.yml
npm install
hexo generate
