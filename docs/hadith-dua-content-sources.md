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


## Additional Hadith collection (100 records)

- Collection: Sahih al-Bukhari, selected narrations 200–328.
- Arabic source dataset: [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api), which declares the Unlicense.
- Each record links to its corresponding [Sunnah.com Sahih al-Bukhari reference](https://sunnah.com/bukhari:200) using its own hadith number.
- All 100 additions are from Sahih al-Bukhari and carry the collection grade `সহিহ`.
- Bengali and English text are Noor-authored concise meaning summaries based on the Arabic narration, not copied third-party translations. The UI should label them as summaries, not full scholarly translations.

The collection source establishes that the narrations belong to Sahih al-Bukhari. The app's original summaries have not yet received independent review by a qualified Hadith scholar. That review is still required before describing the translations as scholar-certified.


The 100 new Arabic narrations were compared with a second independent Hadith dataset for Arabic-text matching and collection grading. A mismatch in the first import of Bukhari 307 was corrected against the direct Sunnah.com Arabic text. The second dataset was used only for verification; no Bengali translation from it was copied.
