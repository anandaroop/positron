# This utility finds unlinked mentions of gene names and links them to their 
# corresponding gene pages, at most once per article.

# rm existing a's

require('node-env-file')(require('path').resolve __dirname, '../.env')
db = require '../api/lib/db'
async = require 'async'
genes = require './gene_list'


# db events
db.on 'connect', -> console.log('database connected')
db.on 'error', (err) -> console.log('database error', err)

# main: get the articles, and process them asynchronously
db.articles.find({ published: true }).limit(10).toArray (err, articles) ->
  return exit err if err
  # console.log articles
  async.each(articles, processArticle, (err, results) -> 
    console.log 'Done. Results = ', results
	)
  process.exit()

# find and link unlinked genes in the lead_paragraph
# and text sections of an article
processArticle = (article, callback) ->
  console.log article.title
  for gene_name, gene_slug of genes
    console.log '  gene: ', gene_name
    text = article.lead_paragraph
    if linkGene(text, gene_name, gene_slug)
      continue
    for section in article.sections when section.type is 'text'
      text = section.body
      if linkGene(text, gene_name, gene_slug)
        continue

# given an html text, check for existence of 
# the gene link, adding it if necessary (at most once)
linkGene = (text, gene_name, gene_slug) ->
  console.log '    ', text
  return false
  # loop over text links' inner text
    # if gene is found
      # return true (link exists)
    # else scan text for gene name
      # if found
        # link it 
        # return true (link exists)
    # return false (link does not exist)
