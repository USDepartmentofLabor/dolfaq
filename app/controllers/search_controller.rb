class SearchController < ApplicationController
  before_action :init
  
  def init
    @context = GovSdk::DataContext.new Dolfaq::API_HOST, Dolfaq::API_KEY, Dolfaq::API_DATA, Dolfaq::API_URI
    @request = GovSdk::DataRequest.new @context
    faquestion = OpenStruct.new
    @dataset = Hash.new
    
    (0..400).step(100) do |n|
      @request.call_api 'FAQ/TopicQuestions', :select => 'FAQID,Question,Answer,Keywords', :skip => n do |results, error|
        if error
        else
          ids = results.xpath("//d:FAQID")
          questions = results.xpath("//d:Question")
          answers = results.xpath("//d:Answer")
          keywords = results.xpath("//d:Keywords")
        
          ids.each_with_index do |item, index|
            faquestion = OpenStruct.new
            faquestion.id = item.text
            faquestion.question = questions[index].text
            faquestion.answer = answers[index].text
            faquestion.keywords = keywords[index].text
            @dataset[item.text] = faquestion
          end
        
        end
      end
      @request.wait_until_finished
    end
      
    
  end
  
  def search
    term = params[:faqquery].downcase
    @searchResults = Array.new
    @dataset.each do |key, d|
      @searchResults << d if d.keywords.downcase.include?(term) ||
                             d.question.downcase.include?(term) ||
                             d.answer.downcase.include?(term)
    end
  end  
end

