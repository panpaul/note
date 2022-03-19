set -x
rm -rf themes/next
git clone https://github.com/next-theme/hexo-theme-next --branch v8.10.1 themes/next
cp themes/_config.yml themes/next/
sed -i "/commonweal/ a\  links: 友情链接" themes/next/languages/zh-CN.yml
sed -i "/commonweal/ a\  links: Links" themes/next/languages/en.yml
yarn install
hexo generate
