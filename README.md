# islamic-app
Islamic educational app for Sadaqah Jariyah. Flutter + Riverpod, offline-first.

## নিয়ম
- হাদিস/দোয়া/৯৯ নামের কনটেন্ট `assets/data/*.json`-এ থাকবে; `verified: true` না হলে অ্যাপে দেখাবে না।
- কনটেন্ট যাচাই ছাড়া কখনো `verified: true` করা যাবে না।

## চালানো
flutter pub get && flutter run

## Geographic data
The additional Bangladesh district records and reference coordinates in `assets/data/cities_bd.json` use Open Admin Data's [Bangladesh Administrative Divisions dataset](https://github.com/open-admin-data/bangladesh-administrative-divisions), licensed under CC BY 4.0. Coordinates are representative district reference points and are not precise user-location coordinates.

