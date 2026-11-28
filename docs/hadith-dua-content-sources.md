# Noor Hadith and Dua content sources

## Hadith

The 12 additions in the 100-record collection use Arabic, Bengali and English editions from [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api), released under the Unlicense. The added narrations are from Sahih al-Bukhari and are referenced individually in `assets/data/hadith.json` using the standard Sunnah.com numbering. Each addition carries a direct reference URL and the collection grade.

The pre-existing 88 records retain their own source, translation and grading metadata. A record is shown only when `verified` is true.

## Duas

The 19 additions bring the total to 100. They are split into:
- 10 morning and evening remembrances.
- 9 duas for common daily situations.

Morning and evening Arabic and English source material is from [Seen-Arabic/Morning-And-Evening-Adhkar-DB](https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB), MIT License. Daily-use Arabic and English source material is from [fitrahive/dua-dhikr](https://github.com/fitrahive/dua-dhikr), MIT License. Bengali meanings for the additions are concise project translations from the cited Arabic.

Each record retains a primary Qur'an or Hadith reference, a direct verification link, the grading where the source supplies one, and its translation/licence note. The morning/evening additions include Sahih or Hasan narrations only. The daily-use additions are drawn from Sahih al-Bukhari and Sahih Muslim.

## Review note

The app's `verified` flag means that the Arabic and reference were checked against the named source and that the narration is Sahih or Hasan where a grading applies. It is not a claim that every Bengali wording has been reviewed by a qualified Hadith scholar. A qualified scholar should review the translations before public release.


## Additional Dua collection (100 records)

- Source repository: [DeenOne Dua API](https://github.com/riadmonir/dua-api)
- Source file: `deenone_all_duas.json`
- The repository README declares an MIT licence.
- Only records with a Qur'an reference or an explicit Sahih al-Bukhari / Sahih Muslim reference were selected. Records with an explicit weak-narration marker were excluded.
- Bengali meanings and Bengali reading aids are retained with the source's attribution. The app keeps each primary reference beside the dua.
- The 100 additions are grouped by the source topic labels. Morning and evening remembrances have their own folder.

The source repository is a community dataset, not a fatwa or scholarly certification. Before a public release, a qualified Qur'an and Hadith reviewer should verify the selected entries and Bengali reading aids.
