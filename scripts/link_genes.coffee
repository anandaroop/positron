# This utility finds unlinked mentions of gene names and links them to their 
# corresponding gene pages, at most once per article.

require('node-env-file')(require('path').resolve __dirname, '../.env')
db = require '../api/lib/db'
mongojs = require 'mongojs'
async = require 'async'
genes = require './gene_list'
ProgressBar = require 'progress'
cheerio = require 'cheerio'
_ = require 'lodash'


# db events
db.on 'connect', -> console.log('database connected')
db.on 'error', (err) -> console.log('database error', err)

# main: get the articles, and process them asynchronously
db.articles.find({ published: true }).limit(50).toArray (err, articles) ->
  exit err if err
  async.each articles, processArticle, (err) -> exit err if err
  process.exit 0

# find and link unlinked genes in the lead_paragraph and text sections of an article
processArticle = (article, callback) ->
  bar = geneProgressBar article._id
  # console.log article.title
  insertedGenes = []
  for gene_name, gene_slug of genes
    bar.tick 1
    url = geneUrl(gene_slug)
    regex = new RegExp("\\b(#{gene_name})\\b", 'i')

    # check lead ¶
    if containsLinkedText(article.lead_paragraph, regex)
      continue # next gene
    if containsText(article.lead_paragraph, regex)
      article.lead_paragraph = insertLink(article.lead_paragraph, regex, url)
      insertedGenes.push(gene_name)
      continue # next gene

    # else no match yet, so check the sections
    for section in article.sections when section.type is 'text'
      if containsLinkedText(section.body, regex)
        break # next gene
      if containsText(section.body, regex)
        section.body = insertLink(section.body, regex, url)
        insertedGenes.push(gene_name)
        break # next gene
  
  if insertedGenes.length
    saveArticle article, callback
    console.log " Inserted", insertedGenes, 'into\n', article.title

  callback()

# generate a gene page link from its slug
geneUrl = (slug) -> "/gene/#{slug}"

geneProgressBar = (name) -> 
  new ProgressBar "[:bar] checked :current/:total Genes in Article #{name}",
      complete: '.',
      incomplete: ' ',
      total: Object.keys(genes).length

# true if the provided htmlFragment contains any <a>s whose inner text matches the supplied pattern
containsLinkedText = (htmlFragment, regex) ->
  if htmlFragment
    $ = cheerio.load(htmlFragment)
    linkInnerTexts = $('a').map((i, elem) -> return $(elem).text()).toArray()
    return _.some(linkInnerTexts, (txt) -> txt.match regex)

# true if the html matches the supplied pattern (trivial, but added for readability)
containsText = (htmlFragment, regex) ->
  htmlFragment.match regex if htmlFragment
    
  
# replace the matching pattern with a link that points to the supplied url
insertLink = (htmlFragment, regex, url) ->
  htmlFragment.replace(regex, "<a class=\"auto-linked-gene\" href=\"#{url}\">$1</a>")

saveArticle = (article, callback) ->
  if process.env.SAVE_ARTICLES
    # log "SAVE", article.id
    db.articles.save article, callback

exit = (err) ->
  console.error "ERROR", err
  process.exit 1
