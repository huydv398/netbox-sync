
echo "Nhập nội dung commit"
read commit
git init
git add .

git commit -m "$commit"
git commit -a 
git push origin main

echo "Done push github: $commit"