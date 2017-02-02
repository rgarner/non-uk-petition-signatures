setupDropdown = (petitionsJson, petitionUrlClicked) ->
  petitionsMenu = $('.petitions.dropdown-menu').empty()

  appendPetitionItem = (petitionJson) ->
    petitionsMenu.append(
      """
        <li>
          <a
            data-petition-url='#{petitionJson.links.self}'
            href='#'>#{petitionJson.attributes.action}</a>
        </li>
      """
    )

  appendPetitionItem(petition) for petition in petitionsJson.data
  petitionsMenu.find('li a').click (e) ->
    url = $(e.currentTarget).attr('data-petition-url')
    petitionUrlClicked(url)

jQuery ->
  if document.getElementById('drpPetitions')
    $.ajax
      url: "https://petition.parliament.uk/petitions.json"
      dataType: "json"
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("Couldn't get petitions JSON - #{textStatus}: #{errorThrown}")
      success: (petitionsJson, _textStatus, _jqXHR) ->
        setupDropdown(petitionsJson, (url) ->
          window._pageManager = new PageManager(url)
          window._pageManager.setup())

