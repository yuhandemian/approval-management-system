package egovframework.example.sample.service;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.annotation.Rollback;
import org.springframework.transaction.annotation.Transactional;

import egovframework.example.common.AbstractServiceTest;

@Transactional
@Rollback
public class EgovSampleServiceTest extends AbstractServiceTest {

    @Autowired
    private EgovSampleService sampleService;

    @Test
    @DisplayName("목록 조회 - 결과가 null이 아니어야 한다")
    void selectSampleList() throws Exception {
        SampleDefaultVO searchVO = new SampleDefaultVO();
        List<?> list = sampleService.selectSampleList(searchVO);
        assertNotNull(list);
    }

    @Test
    @DisplayName("전체 건수 조회 - 초기 데이터 114건")
    void selectSampleListTotCnt() {
        SampleDefaultVO searchVO = new SampleDefaultVO();
        int count = sampleService.selectSampleListTotCnt(searchVO);
        assertEquals(114, count);
    }

    @Test
    @DisplayName("등록 후 건수가 1 증가해야 한다")
    void insertSample() throws Exception {
        SampleDefaultVO searchVO = new SampleDefaultVO();
        int before = sampleService.selectSampleListTotCnt(searchVO);

        SampleVO vo = new SampleVO();
        vo.setName("테스트");
        vo.setDescription("테스트 설명");
        vo.setUseYn("Y");
        vo.setRegUser("tester");
        sampleService.insertSample(vo);

        int after = sampleService.selectSampleListTotCnt(searchVO);
        assertEquals(before + 1, after);
    }

    @Test
    @DisplayName("등록 후 단건 조회 - 이름이 일치해야 한다")
    void selectSample() throws Exception {
        SampleVO vo = new SampleVO();
        vo.setName("단건조회테스트");
        vo.setDescription("desc");
        vo.setUseYn("Y");
        vo.setRegUser("tester");
        String id = sampleService.insertSample(vo);

        SampleVO key = new SampleVO();
        key.setId(id);
        SampleVO result = sampleService.selectSample(key);

        assertNotNull(result);
        assertEquals("단건조회테스트", result.getName());
    }

    @Test
    @DisplayName("수정 후 내용이 변경되어야 한다")
    void updateSample() throws Exception {
        SampleVO vo = new SampleVO();
        vo.setName("수정전");
        vo.setDescription("desc");
        vo.setUseYn("Y");
        vo.setRegUser("tester");
        String id = sampleService.insertSample(vo);

        vo.setId(id);
        vo.setDescription("수정후설명");
        sampleService.updateSample(vo);

        SampleVO key = new SampleVO();
        key.setId(id);
        SampleVO result = sampleService.selectSample(key);
        assertEquals("수정후설명", result.getDescription());
    }

    @Test
    @DisplayName("삭제 후 건수가 1 감소해야 한다")
    void deleteSample() throws Exception {
        SampleVO vo = new SampleVO();
        vo.setName("삭제테스트");
        vo.setDescription("desc");
        vo.setUseYn("Y");
        vo.setRegUser("tester");
        String id = sampleService.insertSample(vo);

        SampleDefaultVO searchVO = new SampleDefaultVO();
        int before = sampleService.selectSampleListTotCnt(searchVO);

        SampleVO key = new SampleVO();
        key.setId(id);
        sampleService.deleteSample(key);

        int after = sampleService.selectSampleListTotCnt(searchVO);
        assertEquals(before - 1, after);
    }
}
