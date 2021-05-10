rm -rf themes/next
git clone https://github.com/next-theme/hexo-theme-next --branch v8.4.0 themes/next
cp themes/_config.yml themes/next/
sed -i "/commonweal/ a\  links: 友情链接" themes/next/languages/zh-CN.yml
sed -i "/commonweal/ a\  links: 友情链接" themes/next/languages/en.yml
npm i
hexo generate
